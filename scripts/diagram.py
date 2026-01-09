#!/usr/bin/env python3
import argparse
import base64
import importlib
import os
import re
import sys


def load_class(module, name, fallback):
    try:
        mod = importlib.import_module(module)
    except Exception:
        return fallback
    return getattr(mod, name, fallback)


def load_hcl(path):
    try:
        import hcl2
    except Exception as exc:
        print("Missing dependency: install python package 'python-hcl2'.", file=sys.stderr)
        print(str(exc), file=sys.stderr)
        raise

    with open(path, "r", encoding="utf-8") as handle:
        return hcl2.load(handle)


def collect_types_from_dir(config_dir, visited):
    if config_dir in visited:
        return set()
    visited.add(config_dir)

    types = set()
    module_sources = []

    for entry in os.listdir(config_dir):
        if not entry.endswith(".tf"):
            continue
        data = load_hcl(os.path.join(config_dir, entry))

        for resources in data.get("resource", []):
            for res_type in resources.keys():
                types.add(res_type)

        for modules in data.get("module", []):
            for module_body in modules.values():
                source = module_body.get("source")
                if isinstance(source, str):
                    module_sources.append(source)

    for source in module_sources:
        if "://" in source or source.startswith("git::"):
            continue
        module_path = os.path.normpath(os.path.join(config_dir, source))
        if os.path.isdir(module_path):
            types.update(collect_types_from_dir(module_path, visited))

    return types


def parse_args():
    parser = argparse.ArgumentParser(description="Generate AWS diagram from Terraform configuration.")
    parser.add_argument("--config-dir", required=True, help="Path to Terraform configuration directory.")
    parser.add_argument("--output", required=True, help="Output path (with or without extension).")
    parser.add_argument("--title", default="AWS Platform", help="Diagram title.")
    return parser.parse_args()


def embed_svg_images(svg_path):
    try:
        with open(svg_path, "r", encoding="utf-8") as handle:
            content = handle.read()
    except FileNotFoundError:
        return False

    def replace(match):
        attr = match.group(1)
        href = match.group(2)
        if href.startswith("data:") or href.startswith("http://") or href.startswith("https://"):
            return match.group(0)

        local_path = href
        if local_path.startswith("file://"):
            local_path = local_path[len("file://") :]
            if os.name == "nt" and local_path.startswith("/"):
                local_path = local_path[1:]

        local_path = os.path.expanduser(local_path)
        if not os.path.isabs(local_path):
            local_path = os.path.normpath(os.path.join(os.path.dirname(svg_path), local_path))

        if not os.path.isfile(local_path):
            return match.group(0)

        with open(local_path, "rb") as image_handle:
            encoded = base64.b64encode(image_handle.read()).decode("ascii")

        ext = os.path.splitext(local_path)[1].lower()
        mime = "image/png"
        if ext == ".svg":
            mime = "image/svg+xml"
        elif ext in {".jpg", ".jpeg"}:
            mime = "image/jpeg"
        elif ext == ".gif":
            mime = "image/gif"

        return f'{attr}="data:{mime};base64,{encoded}"'

    pattern = re.compile(r'((?:xlink:href|href))="([^"]+)"')
    updated = pattern.sub(replace, content)
    if updated == content:
        return False

    with open(svg_path, "w", encoding="utf-8") as handle:
        handle.write(updated)
    return True


def main():
    args = parse_args()
    try:
        from diagrams import Cluster, Diagram, Edge
        from diagrams.aws.general import General
    except Exception as exc:
        print("Missing dependency: install python package 'diagrams' and Graphviz.", file=sys.stderr)
        print(str(exc), file=sys.stderr)
        return 1

    types = collect_types_from_dir(args.config_dir, set())

    has_vpc = "aws_vpc" in types
    has_subnets = "aws_subnet" in types
    has_nat = "aws_nat_gateway" in types
    has_alb = "aws_lb" in types
    has_lb_target_group = "aws_lb_target_group" in types
    has_ecs = "aws_ecs_service" in types
    has_ecs_cluster = "aws_ecs_cluster" in types
    has_ecs_task_def = "aws_ecs_task_definition" in types
    has_ecs_capacity_provider = "aws_ecs_capacity_provider" in types
    has_ecs_cluster_capacity_providers = "aws_ecs_cluster_capacity_providers" in types
    has_asg = "aws_autoscaling_group" in types
    has_launch_template = "aws_launch_template" in types
    has_ec2_instance = "aws_instance" in types
    has_rds = "aws_db_instance" in types
    has_db_subnet_group = "aws_db_subnet_group" in types
    has_s3 = "aws_s3_bucket" in types
    has_ddb = "aws_dynamodb_table" in types
    has_kms = "aws_kms_key" in types
    has_igw = "aws_internet_gateway" in types
    has_route_table = "aws_route_table" in types
    has_security_group = "aws_security_group" in types
    has_flow_log = "aws_flow_log" in types
    has_cloudwatch_log_group = "aws_cloudwatch_log_group" in types
    has_sns = "aws_sns_topic" in types
    has_alarms = "aws_cloudwatch_metric_alarm" in types
    has_eip = "aws_eip" in types

    if has_subnets:
        public_subnets = True
        private_subnets = True
    else:
        public_subnets = False
        private_subnets = False

    VPC = load_class("diagrams.aws.network", "VPC", General)
    ALB = load_class("diagrams.aws.network", "ALB", General)
    NAT = load_class("diagrams.aws.network", "NATGateway", General)
    InternetGateway = load_class("diagrams.aws.network", "InternetGateway", General)
    RouteTable = load_class("diagrams.aws.network", "RouteTable", General)
    PublicSubnet = load_class("diagrams.aws.network", "PublicSubnet", General)
    PrivateSubnet = load_class("diagrams.aws.network", "PrivateSubnet", General)
    ElasticIp = load_class("diagrams.aws.network", "ElasticIp", General)
    TargetGroup = load_class("diagrams.aws.network", "TargetGroup", General)

    ECS = load_class("diagrams.aws.compute", "ECS", General)
    AutoScaling = load_class("diagrams.aws.compute", "AutoScaling", General)
    EC2 = load_class("diagrams.aws.compute", "EC2", General)
    LaunchTemplate = load_class("diagrams.aws.compute", "LaunchTemplate", General)

    RDS = load_class("diagrams.aws.database", "RDS", General)
    DynamoDB = load_class("diagrams.aws.database", "DynamoDB", General)

    S3 = load_class("diagrams.aws.storage", "S3", General)
    KMS = load_class("diagrams.aws.security", "KMS", General)
    SecurityGroup = load_class("diagrams.aws.security", "SecurityGroup", General)
    SNS = load_class("diagrams.aws.integration", "SNS", General)
    Cloudwatch = load_class("diagrams.aws.management", "Cloudwatch", General)

    output_path = args.output
    output_dir = os.path.dirname(output_path)
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)

    filename = output_path
    outformat = "png"
    if output_path.endswith(".svg"):
        filename = output_path[:-4]
        outformat = "svg"
    elif output_path.endswith(".png"):
        filename = output_path[:-4]
        outformat = "png"

    node_attr = {"fixedsize": "true", "width": "0.9", "height": "0.9"}
    with Diagram(
        args.title,
        filename=filename,
        outformat=outformat,
        show=False,
        direction="LR",
        node_attr=node_attr,
    ):
        kms_node = None
        s3_node = None
        ddb_node = None
        sns_node = None
        cw_node = None
        log_group_node = None
        flow_log_node = None

        platform_cluster_name = (
            "Bootstrap" if os.path.basename(os.path.abspath(args.config_dir)) == "bootstrap" else "Platform Services"
        )
        if has_s3 or has_ddb or has_sns or has_kms:
            with Cluster(platform_cluster_name):
                if has_kms:
                    kms_node = KMS("KMS Keys")
                if has_s3:
                    s3_node = S3("S3 Buckets")
                    if kms_node:
                        s3_node >> Edge(label="encrypt") >> kms_node
                if has_ddb:
                    ddb_node = DynamoDB("DynamoDB")
                    if kms_node:
                        ddb_node >> Edge(label="encrypt") >> kms_node
                if has_sns:
                    sns_node = SNS("SNS Topics")
                    if kms_node:
                        sns_node >> Edge(label="encrypt") >> kms_node

        if has_cloudwatch_log_group or has_alarms:
            with Cluster("Observability"):
                if has_cloudwatch_log_group:
                    log_group_node = Cloudwatch("Log Groups")
                if has_alarms:
                    cw_node = Cloudwatch("Alarms")
                    if sns_node:
                        cw_node >> Edge(label="notify") >> sns_node

        compute_nodes = []
        ecs_service_node = None
        asg_node = None
        rds_node = None
        db_subnet_group_node = None
        alb_node = None
        nat_node = None
        igw_node = None
        route_table_node = None
        sg_node = None
        eip_node = None
        target_group_node = None
        ecs_cluster_node = None
        ecs_task_def_node = None
        ecs_capacity_provider_node = None
        launch_template_node = None
        ec2_instance_node = None

        if has_vpc:
            with Cluster("VPC"):
                if has_igw:
                    igw_node = InternetGateway("IGW")
                if has_route_table:
                    route_table_node = RouteTable("Route Tables")
                if has_security_group:
                    sg_node = SecurityGroup("Security Groups")
                if has_flow_log:
                    flow_log_node = Cloudwatch("VPC Flow Logs")
                    if log_group_node:
                        flow_log_node >> Edge(label="deliver") >> log_group_node

                if public_subnets:
                    with Cluster("Public Subnets"):
                        if has_alb:
                            alb_node = ALB("ALB")
                            if has_lb_target_group:
                                target_group_node = TargetGroup("Target Group")
                        if has_nat:
                            nat_node = NAT("NAT GW")
                            if has_eip:
                                eip_node = ElasticIp("Elastic IP")
                                nat_node >> Edge(label="uses") >> eip_node
                        PublicSubnet("Public Subnets")
                else:
                    if has_alb:
                        alb_node = ALB("ALB")
                        if has_lb_target_group:
                            target_group_node = TargetGroup("Target Group")
                    if has_nat:
                        nat_node = NAT("NAT GW")
                        if has_eip:
                            eip_node = ElasticIp("Elastic IP")
                            nat_node >> Edge(label="uses") >> eip_node

                if private_subnets:
                    with Cluster("Private Subnets"):
                        if has_ecs_cluster:
                            ecs_cluster_node = ECS("ECS Cluster")
                        if has_ecs:
                            ecs_service_node = ECS("ECS Service")
                            compute_nodes.append(ecs_service_node)
                        if has_ecs_task_def:
                            ecs_task_def_node = ECS("Task Definition")
                        if has_ecs_capacity_provider or has_ecs_cluster_capacity_providers:
                            ecs_capacity_provider_node = ECS("Capacity Provider")
                        if has_asg:
                            asg_node = AutoScaling("EC2 ASG")
                            compute_nodes.append(asg_node)
                        if has_launch_template:
                            launch_template_node = LaunchTemplate("Launch Template")
                        if has_ec2_instance:
                            ec2_instance_node = EC2("EC2 Instances")
                            compute_nodes.append(ec2_instance_node)
                        if has_rds:
                            rds_node = RDS("RDS")
                        if has_db_subnet_group:
                            db_subnet_group_node = RDS("DB Subnet Group")
                        PrivateSubnet("Private Subnets")
                else:
                    if has_ecs_cluster:
                        ecs_cluster_node = ECS("ECS Cluster")
                    if has_ecs:
                        ecs_service_node = ECS("ECS Service")
                        compute_nodes.append(ecs_service_node)
                    if has_ecs_task_def:
                        ecs_task_def_node = ECS("Task Definition")
                    if has_ecs_capacity_provider or has_ecs_cluster_capacity_providers:
                        ecs_capacity_provider_node = ECS("Capacity Provider")
                    if has_asg:
                        asg_node = AutoScaling("EC2 ASG")
                        compute_nodes.append(asg_node)
                    if has_launch_template:
                        launch_template_node = LaunchTemplate("Launch Template")
                    if has_ec2_instance:
                        ec2_instance_node = EC2("EC2 Instances")
                        compute_nodes.append(ec2_instance_node)
                    if has_rds:
                        rds_node = RDS("RDS")
                    if has_db_subnet_group:
                        db_subnet_group_node = RDS("DB Subnet Group")

        else:
            if has_ecs_cluster:
                ecs_cluster_node = ECS("ECS Cluster")
            if has_ecs:
                ecs_service_node = ECS("ECS Service")
                compute_nodes.append(ecs_service_node)
            if has_ecs_task_def:
                ecs_task_def_node = ECS("Task Definition")
            if has_ecs_capacity_provider or has_ecs_cluster_capacity_providers:
                ecs_capacity_provider_node = ECS("Capacity Provider")
            if has_asg:
                asg_node = AutoScaling("EC2 ASG")
                compute_nodes.append(asg_node)
            if has_launch_template:
                launch_template_node = LaunchTemplate("Launch Template")
            if has_ec2_instance:
                ec2_instance_node = EC2("EC2 Instances")
                compute_nodes.append(ec2_instance_node)
            if has_rds:
                rds_node = RDS("RDS")
            if has_db_subnet_group:
                db_subnet_group_node = RDS("DB Subnet Group")
            if has_alb:
                alb_node = ALB("ALB")
                if has_lb_target_group:
                    target_group_node = TargetGroup("Target Group")
            if has_nat:
                nat_node = NAT("NAT GW")
                if has_eip:
                    eip_node = ElasticIp("Elastic IP")
                    nat_node >> Edge(label="uses") >> eip_node

        if ecs_cluster_node and ecs_service_node:
            ecs_cluster_node >> ecs_service_node
        if ecs_task_def_node and ecs_service_node:
            ecs_task_def_node >> ecs_service_node
        if ecs_capacity_provider_node and asg_node:
            ecs_capacity_provider_node >> asg_node
        if launch_template_node and asg_node:
            launch_template_node >> asg_node
        if alb_node and compute_nodes:
            if target_group_node:
                alb_node >> target_group_node
                target_group_node >> compute_nodes
            else:
                alb_node >> compute_nodes
        if db_subnet_group_node and rds_node:
            db_subnet_group_node >> rds_node
        if compute_nodes and rds_node:
            for node in compute_nodes:
                node >> rds_node
            if kms_node:
                rds_node >> Edge(label="encrypt") >> kms_node
        if compute_nodes and nat_node:
            for node in compute_nodes:
                node >> nat_node

    if outformat == "svg":
        svg_path = f"{filename}.svg"
        embed_svg_images(svg_path)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
