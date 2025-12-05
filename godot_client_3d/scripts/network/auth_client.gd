extends Node
class_name AuthClient

## Simple Nakama auth client + token store.
## Flow:
## - Login or Register via HTTP
## - Store session token
## - Godot gateway uses this token to connect via WebSocket

signal login_success
signal login_failed(reason: String)

@export var nakama_base_url: String = "http://localhost:7350"

var token: String = ""
var username: String = ""
var world_ws: String = "ws://localhost:8080/ws"
var character_name: String = ""
var appearance: Dictionary = {}

var _http: HTTPRequest


func _ready() -> void:
	if not _http:
		_http = HTTPRequest.new()
		add_child(_http)
		_http.request_completed.connect(_on_http_completed)


## Login existing account (no registration). Account must be created manually beforehand.
func login_email_existing(email: String, password: String) -> void:
	if not _http:
		_ready()
	var url := nakama_base_url + "/v2/account/authenticate/email?create=false"
	var body := {
		"email": email,
		"password": password
	}
	var headers := ["Content-Type: application/json"]
	var err := _http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		emit_signal("login_failed", "HTTP error: %d" % err)


func set_token_manual(new_token: String, new_username: String = "") -> void:
	token = new_token
	username = new_username
	emit_signal("login_success")


func set_world_ws(url: String) -> void:
	world_ws = url


func _on_http_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		var txt := body.get_string_from_utf8()
		emit_signal("login_failed", "HTTP %d: %s" % [response_code, txt])
		return
	var txt := body.get_string_from_utf8()
	var data := JSON.parse_string(txt)
	if typeof(data) != TYPE_DICTIONARY:
		emit_signal("login_failed", "invalid response")
		return
	token = str(data.get("token", ""))
	username = str(data.get("username", ""))
	if token == "":
		emit_signal("login_failed", "no token in response")
		return
	emit_signal("login_success")


