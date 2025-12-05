extends Node

##
## Global gameplay / project constants for Isleborn Online client.
## In early prototype this is mostly a placeholder so that higher–level
## systems already have a central place to import shared values.
##

const PROJECT_NAME := "Isleborn Online"
const VERSION := "0.1.0"

const MAX_PLAYER_LEVEL := 50
const MAX_ISLAND_LEVEL := 50

const TIER_T1 := 1
const TIER_T2 := 2
const TIER_T3 := 3
const TIER_T4 := 4
const TIER_T5 := 5

var GATEWAY_WS_URL := "ws://localhost:8090"
var ISLAND_SERVICE_URL := "http://localhost:5001"
var WEB_FRONTEND_URL := "http://localhost:5000"

func _ready() -> void:
        var replit_domain := OS.get_environment("REPLIT_DOMAINS")
        if replit_domain != "":
                GATEWAY_WS_URL = "wss://" + replit_domain.replace("-00-", "-8090-00-")
                ISLAND_SERVICE_URL = "https://" + replit_domain.replace("-00-", "-5001-00-")
                WEB_FRONTEND_URL = "https://" + replit_domain
        print("[Constants] Isleborn Online v", VERSION)
        print("[Constants] Gateway WS: ", GATEWAY_WS_URL)
        print("[Constants] Island Service: ", ISLAND_SERVICE_URL)


