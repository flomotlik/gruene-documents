from aws_cdk import (
    # Duration,
    Stack,
    SecretValue,
    aws_ec2 as ec2,
    aws_ecs as ecs,
    aws_ecs_patterns as ecs_patterns,
    aws_ecr as ecr,
    aws_rds as rds,
    aws_iam as iam,
    aws_secretsmanager as secretsmanager,
    aws_s3 as s3,
    aws_certificatemanager as certificatemanager,
    aws_route53 as route53,
    aws_certificatemanager as acm,
)
from constructs import Construct
import boto3

ecr_client = boto3.client("ecr")


class CdkStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)
        project_name = "GreenDocuments"

        vpc = ec2.Vpc(
            self,
            project_name,
            max_azs=2,
            nat_gateways=0,
            subnet_configuration=[
                ec2.SubnetConfiguration(
                    name="Public", subnet_type=ec2.SubnetType.PUBLIC
                ),
                ec2.SubnetConfiguration(
                    name="Private", subnet_type=ec2.SubnetType.PRIVATE_WITH_EGRESS
                ),
            ],
        )  # default is all AZs in region

        repository = ecr.Repository(self, "Repository")

        rails_master_key = secretsmanager.Secret(
            self,
            "SecretKeyBase",
            secret_object_value={
                "secret_key_base": SecretValue.unsafe_plain_text("DEFAULT"),
            },
        )

        db_instance = rds.DatabaseInstance(
            self,
            "DBInstance",
            engine=rds.DatabaseInstanceEngine.POSTGRES,
            instance_type=ec2.InstanceType.of(
                ec2.InstanceClass.T4G, ec2.InstanceSize.MICRO
            ),
            vpc=vpc,
        )

        rails_tasks_taskdefinition = ecs.FargateTaskDefinition(
            self,
            "TaskDefinitionRails",
            cpu=256,
            memory_limit_mib=512,
            runtime_platform=ecs.RuntimePlatform(
                operating_system_family=ecs.OperatingSystemFamily.LINUX,
                cpu_architecture=ecs.CpuArchitecture.ARM64,
            ),
        )
        documents_ecr_image = ecs.EcrImage.from_ecr_repository(repository, "latest")
        storage_bucket = s3.Bucket(self, "StorageBucket", versioned=True)
        storage_bucket.grant_read_write(rails_tasks_taskdefinition.task_role)

        web_container = rails_tasks_taskdefinition.add_container(
            "web",
            image=documents_ecr_image,
            logging=ecs.LogDrivers.aws_logs(stream_prefix="rails"),
            environment={
                "RAILS_ENV": "production",
                "RAILS_LOG_TO_STDOUT": "true",
                "STORAGE_BUCKET": storage_bucket.bucket_name,
            },
            secrets={
                "DATABASE_USERNAME": ecs.Secret.from_secrets_manager(
                    db_instance.secret, field="username"
                ),
                "DATABASE_PASSWORD": ecs.Secret.from_secrets_manager(
                    db_instance.secret, field="password"
                ),
                "DATABASE_HOST": ecs.Secret.from_secrets_manager(
                    db_instance.secret, field="host"
                ),
                "DATABASE_PORT": ecs.Secret.from_secrets_manager(
                    db_instance.secret, field="port"
                ),
                "SECRET_KEY_BASE": ecs.Secret.from_secrets_manager(
                    rails_master_key, field="secret_key_base"
                ),
            },
        )

        web_container.add_port_mappings(ecs.PortMapping(container_port=3000))

        rails_tasks_taskdefinition.add_container(
            "que",
            image=documents_ecr_image,
            command=["bundle", "exec", "que"],
            logging=ecs.LogDrivers.aws_logs(stream_prefix="que"),
            environment={
                "RAILS_ENV": "production",
                "RAILS_LOG_TO_STDOUT": "true",
                "STORAGE_BUCKET": storage_bucket.bucket_name,
            },
            secrets={
                "DATABASE_USERNAME": ecs.Secret.from_secrets_manager(
                    db_instance.secret, field="username"
                ),
                "DATABASE_PASSWORD": ecs.Secret.from_secrets_manager(
                    db_instance.secret, field="password"
                ),
                "DATABASE_HOST": ecs.Secret.from_secrets_manager(
                    db_instance.secret, field="host"
                ),
                "DATABASE_PORT": ecs.Secret.from_secrets_manager(
                    db_instance.secret, field="port"
                ),
                "SECRET_KEY_BASE": ecs.Secret.from_secrets_manager(
                    rails_master_key, field="secret_key_base"
                ),
            },
        )

        hosted_zone = route53.HostedZone.from_lookup(
            self, "Zone", domain_name="theserverlessway.com."
        )

        domain = "green-documents.theserverlessway.com"
        cert = acm.Certificate(
            self,
            "Certificate",
            domain_name=domain,
            validation=acm.CertificateValidation.from_dns(hosted_zone),
        )

        ecs_cluster = ecs.Cluster(
            self, "Cluster", vpc=vpc, enable_fargate_capacity_providers=True
        )
        fargate_service = ecs_patterns.ApplicationLoadBalancedFargateService(
            self,
            "Service",
            cluster=ecs_cluster,
            desired_count=1,
            task_definition=rails_tasks_taskdefinition,
            assign_public_ip=True,
            task_subnets=ec2.SubnetSelection(subnet_type=ec2.SubnetType.PUBLIC),
            public_load_balancer=True,
            circuit_breaker=ecs.DeploymentCircuitBreaker(rollback=False),
            certificate=cert,
            domain_name=domain,
            domain_zone=hosted_zone,
            capacity_provider_strategies=[
                ecs.CapacityProviderStrategy(
                    capacity_provider="FARGATE", weight=1, base=1
                )
            ],
        )

        fargate_service.target_group.configure_health_check(path="/users/sign_in")

        db_instance.connections.allow_default_port_from(fargate_service.service)
