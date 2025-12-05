#!/usr/bin/env python3
"""
instance_manager/app.py
Simple HTTP service to manage per-player Godot headless instances.
This is a minimal example that calls docker via subprocess to run/stop containers.
In production, use orchestration (Kubernetes) or a proper Docker SDK with robust error handling.
"""
from flask import Flask, request, jsonify, abort
import os, subprocess, uuid, json, shlex, time

app = Flask(__name__)
GODOT_IMAGE = os.environ.get("GODOT_IMAGE", "isleborn/godot_server:latest")
GODOT_EXPORT_PATH = os.environ.get("GODOT_EXPORT_PATH", "/export/isleborn_server.x86_64")
NETWORK = os.environ.get("DOCKER_NETWORK", "bridge")

# Simple in-memory registry: owner -> container_id
registry = {}

def docker_run_instance(owner, owner_dir=None):
    # create a unique container name
    name = f"isleborn_world_{owner}"
    # mount owner specific folder if provided (for persistent island state), else use default
    mounts = ""
    if owner_dir:
        mounts = f"-v {shlex.quote(owner_dir)}:/data:rw"
    cmd = f"docker run -d --rm --name {name} --network {NETWORK} {mounts} {GODOT_IMAGE} --server --port 8090"
    proc = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if proc.returncode != 0:
        raise RuntimeError(f"docker run failed: {proc.stderr}")
    container_id = proc.stdout.strip()
    return container_id

def docker_stop_instance(container_id_or_name):
    cmd = f"docker stop {shlex.quote(container_id_or_name)}"
    proc = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if proc.returncode != 0:
        raise RuntimeError(f"docker stop failed: {proc.stderr}")
    return proc.stdout.strip()

@app.route("/start/<owner>", methods=["POST"])
def start_instance(owner):
    if owner in registry:
        return jsonify({"status":"already_running","owner":owner,"container":registry[owner]})
    owner_dir = request.json.get("owner_dir") if request.json else None
    try:
        cid = docker_run_instance(owner, owner_dir)
        registry[owner] = cid
        return jsonify({"status":"started","owner":owner,"container":cid})
    except Exception as e:
        return jsonify({"status":"error","error":str(e)}), 500

@app.route("/stop/<owner>", methods=["POST"])
def stop_instance(owner):
    if owner not in registry:
        return jsonify({"status":"not_found","owner":owner}), 404
    cid = registry[owner]
    try:
        out = docker_stop_instance(cid)
        registry.pop(owner, None)
        return jsonify({"status":"stopped","owner":owner,"output":out})
    except Exception as e:
        return jsonify({"status":"error","error":str(e)}), 500

@app.route("/status/<owner>", methods=["GET"])
def status(owner):
    if owner in registry:
        return jsonify({"status":"running","owner":owner,"container":registry[owner]})
    return jsonify({"status":"stopped","owner":owner})

@app.route("/list", methods=["GET"])
def list_instances():
    return jsonify(registry)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "5100")))
