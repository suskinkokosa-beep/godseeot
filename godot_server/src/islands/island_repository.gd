extends Node
class_name IslandRepository

## Thin abstraction over current JSON/HTTP-based island persistence.
## Wraps the logic that lives in server.gd today so it can be moved here over time.

var island_service_url: String = "http://island_service:5000"

var _http_request: HTTPRequest

func setup(http_request: HTTPRequest, base_url: String) -> void:
	_http_request = http_request
	island_service_url = base_url


func load_island(owner: String) -> Dictionary:
	if _http_request == null:
		return {}
	var url := island_service_url + "/island/" + owner
	var err := _http_request.request(url, [], true, HTTPClient.METHOD_GET)
	if err != OK:
		print("IslandRepository.load_island: request failed", err)
		return {}
	yield(_http_request, "request_completed")
	var body := _http_request.get_response_body()
	if body.size() == 0:
		return {}
	var txt := body.get_string_from_utf8()
	var parsed := JSON.parse(txt)
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	return {}


func save_island(owner: String, island: Dictionary) -> bool:
	if _http_request == null:
		return false
	var url := island_service_url + "/island/" + owner
	var payload := {"island": island}
	var txt := JSON.print(payload)
	var headers := ["Content-Type: application/json"]
	var err := _http_request.request(url, headers, true, HTTPClient.METHOD_PUT, txt.to_utf8())
	if err != OK:
		print("IslandRepository.save_island: request failed", err)
		return false
	yield(_http_request, "request_completed")
	return true


