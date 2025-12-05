#!/usr/bin/env python3
"""
generate_island.py
Procedural island JSON generator for Isleborn.
Usage:
  python generate_island.py --owner <owner_id> [--seed 123] [--radius 3.0] [--out ./godot_server/islands]

Produces island_<owner>.json with fields: owner, owner_name, level, size, bounds, spawn_pos, resources, buildings
"""
import argparse, os, json, random, math, datetime

RESOURCE_TYPES = ["palm_tree", "stone_node", "fish_school"]

def generate(owner, owner_name=None, seed=None, radius=3.0):
    if seed is None:
        seed = int.from_bytes(os.urandom(4), "big")
    rnd = random.Random(seed)
    owner_name = owner_name or ("Player_" + owner[:6])
    # size approx proportional to radius
    size = {"width": radius*2, "height": radius*2}
    # spawn on beach: pick point near edge
    angle = rnd.random() * 2 * math.pi
    spawn_pos = [radius * 0.85 * math.cos(angle), 0.0, radius * 0.85 * math.sin(angle)]
    # resources: place N resources within radius avoiding spawn
    resources = []
    n_trees = rnd.randint(2,5)
    n_stones = rnd.randint(1,4)
    for i in range(n_trees):
        r = rnd.random() * (radius * 0.7)
        a = rnd.random() * 2 * math.pi
        x = r * math.cos(a)
        z = r * math.sin(a)
        resources.append({"type":"palm_tree","pos":[round(x,3),0.0,round(z,3)],"amount":rnd.randint(3,8)})
    for i in range(n_stones):
        r = rnd.random() * (radius * 0.8)
        a = rnd.random() * 2 * math.pi
        x = r * math.cos(a)
        z = r * math.sin(a)
        resources.append({"type":"stone_node","pos":[round(x,3),0.0,round(z,3)],"amount":rnd.randint(2,6)})
    # buildings: default campfire near center
    buildings = [{"type":"campfire","pos":[0.5,0.0,0.2]}]
    island = {
        "owner": owner,
        "owner_name": owner_name,
        "level": 1,
        "size": size,
        "bounds": {"radius": radius},
        "spawn_pos": spawn_pos,
        "resources": resources,
        "buildings": buildings,
        "seed": seed,
        "generated_at": datetime.datetime.utcnow().isoformat() + "Z"
    }
    return island

def save_island(island, out_dir):
    os.makedirs(out_dir, exist_ok=True)
    path = os.path.join(out_dir, f"island_{island['owner']}.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(island, f, indent=2)
    return path

if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--owner", required=True)
    p.add_argument("--owner-name", default=None)
    p.add_argument("--seed", type=int, default=None)
    p.add_argument("--radius", type=float, default=3.0)
    p.add_argument("--out", default="./godot_server/islands")
    args = p.parse_args()
    isl = generate(args.owner, args.owner_name, args.seed, args.radius)
    path = save_island(isl, args.out)
    print("Wrote", path)
