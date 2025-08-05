#!/usr/bin/env python3
# BIA FastMCP Server - Produção
from fastmcp import FastMCP
import subprocess
import os
import json
from datetime import datetime

mcp = FastMCP(name="BIA FastMCP Server - Production")

# ===== COMANDOS DE INFRAESTRUTURA =====

@mcp.tool()
def list_ec2_instances() -> dict:
    """Lista todas as instâncias EC2 da conta."""
    try:
        result = subprocess.run([
            "aws", "ec2", "describe-instances",
            "--query", "Reservations[*].Instances[*].{ID:InstanceId,Name:Tags[?Key=='Name'].Value|[0],State:State.Name,Type:InstanceType,IP:PublicIpAddress}",
            "--output", "json"
        ], capture_output=True, text=True)
        
        if result.returncode == 0:
            instances = json.loads(result.stdout)
            flat_instances = [item for sublist in instances for item in sublist]
            return {
                "success": True,
                "count": len(flat_instances),
                "instances": flat_instances[:10]
            }
        else:
            return {"success": False, "error": result.stderr}
    except Exception as e:
        return {"success": False, "error": str(e)}

@mcp.tool()
def create_security_group(name: str, description: str) -> dict:
    """Cria um novo Security Group."""
    try:
        result = subprocess.run([
            "aws", "ec2", "create-security-group",
            "--group-name", name,
            "--description", description,
            "--output", "json"
        ], capture_output=True, text=True)
        
        if result.returncode == 0:
            sg_data = json.loads(result.stdout)
            return {
                "success": True,
                "security_group_id": sg_data.get("GroupId"),
                "message": f"Security Group '{name}' criado com sucesso!"
            }
        else:
            return {"success": False, "error": result.stderr}
    except Exception as e:
        return {"success": False, "error": str(e)}

@mcp.tool()
def check_ecs_cluster_status() -> dict:
    """Verifica status do cluster ECS do projeto BIA."""
    try:
        result = subprocess.run([
            "aws", "ecs", "describe-clusters",
            "--clusters", "cluster-bia-alb",
            "--include", "ATTACHMENTS",
            "--output", "json"
        ], capture_output=True, text=True)
        
        if result.returncode == 0:
            cluster_data = json.loads(result.stdout)
            if cluster_data.get("clusters"):
                cluster = cluster_data["clusters"][0]
                return {
                    "success": True,
                    "cluster_name": cluster.get("clusterName"),
                    "status": cluster.get("status"),
                    "running_tasks": cluster.get("runningTasksCount"),
                    "pending_tasks": cluster.get("pendingTasksCount"),
                    "active_services": cluster.get("activeServicesCount"),
                    "registered_instances": cluster.get("registeredContainerInstancesCount")
                }
            else:
                return {"success": False, "error": "Cluster cluster-bia-alb não encontrado"}
        else:
            return {"success": False, "error": result.stderr}
    except Exception as e:
        return {"success": False, "error": str(e)}

@mcp.tool()
def bia_project_info() -> dict:
    """Informações sobre o projeto BIA."""
    return {
        "name": "Projeto BIA",
        "version": "4.2.0",
        "bootcamp": "28/07 a 03/08/2025",
        "creator": "Henrylle Maia",
        "philosophy": "Simplicidade para alunos em aprendizado",
        "repository": "https://github.com/henrylle/bia",
        "instance": "Production"
    }

@mcp.resource("bia://status")
def bia_status() -> dict:
    """Status atual do projeto BIA."""
    return {
        "fastmcp_version": "production",
        "aws_integration": True,
        "instance_type": "Original Production",
        "automated": True,
        "timestamp": datetime.now().isoformat()
    }

if __name__ == "__main__":
    print("🎯 Servidor BIA FastMCP (Produção) iniciado!")
    print("🚀 Comandos disponíveis:")
    print("   - list_ec2_instances()")
    print("   - create_security_group(name, description)")
    print("   - check_ecs_cluster_status()")
    print("   - bia_project_info()")
    print("🌐 Rodando em background via systemd")
