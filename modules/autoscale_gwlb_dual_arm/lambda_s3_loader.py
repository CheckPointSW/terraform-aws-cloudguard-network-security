import boto3
import os
import json
import sys
import logging
from botocore.exceptions import ClientError

# Configure structured logging for better CloudWatch Insights queries
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def fetch_and_pin_latest_s3_version(bucket, key, context):
    """
    Fetch the latest S3 version and pin it to Lambda environment variable.
    Returns the version_id.

    Args:
        bucket: S3 bucket name
        key: S3 object key
        context: Lambda context
    """
    s3_client = boto3.client('s3')
    lambda_client = boto3.client('lambda')

    response = s3_client.get_object(Bucket=bucket, Key=key)
    version_id = response['VersionId']
    logger.info(f"Latest version: {version_id}. Pinning to Lambda environment...")

    try:
        lambda_config = lambda_client.get_function_configuration(
            FunctionName=context.function_name)
        env_vars = lambda_config.get('Environment', {}).get('Variables', {})
        env_vars['S3_VERSION_ID'] = version_id

        lambda_client.update_function_configuration(
            FunctionName=context.function_name,
            Environment={'Variables': env_vars}
        )
        logger.info(f"Successfully pinned version {version_id}")
    except ClientError as update_error:
        if update_error.response['Error']['Code'] == 'ResourceConflictException':
            logger.info(f"Concurrent update in progress - another instance is pinning the version. Using fetched version "
                        f"{version_id}.")
        else:
            logger.warning(f"Could not pin version to Lambda env var: {update_error}")
    except Exception as update_error:
        logger.warning(f"Could not pin version to Lambda env var: {update_error}")

    return version_id


def execute_s3_code(bucket, key, version_id, event, context):
    """
    Download and execute code from S3.
    Returns the result from the downloaded lambda_handler.
    """
    s3_client = boto3.client('s3')

    # Download the code from S3 using the pinned version
    response = s3_client.get_object(Bucket=bucket, Key=key, VersionId=version_id)
    code = response['Body'].read().decode('utf-8')
    logger.info(f"Using Lambda code version: {version_id}")

    # Create a new module namespace to execute the downloaded code
    module_globals = {
        '__name__': '__main__',
        'boto3': boto3,
        'json': json,
        'os': os,
        'sys': sys,
        'ClientError': ClientError
    }

    # Execute the downloaded code
    exec(code, module_globals)

    # Call the lambda_handler function from the downloaded code
    if 'lambda_handler' in module_globals:
        return module_globals['lambda_handler'](event, context)
    else:
        raise ValueError("No lambda_handler function found in downloaded code")


def handle_bootstrap_error(event, error):
    """
    Handle errors in bootstrap Lambda by completing lifecycle actions if needed.
    """
    logger.error(f"Error in bootstrap Lambda: {str(error)}")

    # For ASG lifecycle hooks, we should complete the action to avoid hanging
    if 'detail' in event and 'LifecycleHookName' in event['detail']:
        asg_client = boto3.client('autoscaling')
        try:
            asg_client.complete_lifecycle_action(
                LifecycleHookName=event['detail']['LifecycleHookName'],
                AutoScalingGroupName=event['detail']['AutoScalingGroupName'],
                InstanceId=event['detail']['EC2InstanceId'],
                LifecycleActionResult='ABANDON'
            )
        except ClientError as validation_error:
            # Lifecycle action may have already completed or timed out - this is not fatal
            if validation_error.response['Error']['Code'] == 'ValidationError':
                error_msg = validation_error.response['Error']['Message']
                if 'No active Lifecycle Action found' in error_msg:
                    logger.info(f"Lifecycle action already completed or timed out: {error_msg}")
                else:
                    logger.warning(f"Validation error completing lifecycle action: {error_msg}")
            else:
                logger.error(f"AWS error completing lifecycle action: {str(validation_error)}")
        except Exception as complete_error:
            logger.error(f"Error completing lifecycle action: {str(complete_error)}")

    return {
        'statusCode': 500,
        'body': json.dumps(f'Error: {str(error)}')
    }


def lambda_handler(event, context):
    """
    Bootstrap Lambda that fetches and executes the actual code from S3.

    Behavior controlled by LAMBDA_AUTO_UPDATE environment variable:
    - false (default): On first run, fetches latest version and pins it to S3_VERSION_ID env var.
                       To update, manually change S3_VERSION_ID in AWS Console.
    - true: Always checks for and updates to the newest version from S3 on each execution.
    """
    try:
        # Get S3 configuration from environment variables
        bucket = os.environ.get('S3_BUCKET')
        key = os.environ.get('S3_KEY')
        version_id = os.environ.get('S3_VERSION_ID')
        auto_update = os.environ.get('LAMBDA_AUTO_UPDATE', 'false').lower() == 'true'

        if not bucket or not key:
            raise ValueError("S3_BUCKET and S3_KEY environment variables must be set")

        # If auto_update is enabled, always fetch the latest version
        if auto_update:
            logger.info("Auto-update enabled. Fetching latest version from S3...")
            version_id = fetch_and_pin_latest_s3_version(bucket, key, context)

        # If no version pinned yet, fetch latest and pin it
        elif not version_id:
            logger.info("No version pinned. Fetching latest version from S3...")
            version_id = fetch_and_pin_latest_s3_version(bucket, key, context)

        # Download and execute the code
        return execute_s3_code(bucket, key, version_id, event, context)

    except Exception as e:
        return handle_bootstrap_error(event, e)
