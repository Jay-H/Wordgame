# Client.gd
extends Node

# IMPORTANT: Replace this with the server computer's actual local IP address!
const SERVER_IP = "99.232.235.123" 
const SERVER_PORT = 9081

var client = StreamPeerTCP.new()
var has_sent = false # Add a flag to ensure we only send once.

func _ready():
	# Attempt to connect to the server.
	print("Connecting to server at %s:%d..." % [SERVER_IP, SERVER_PORT])
	var error = client.connect_to_host(SERVER_IP, SERVER_PORT)
	if error != OK:
		print("Error: Could not connect to server.")
		set_process(false)

func _process(delta):
	# Keep the connection alive.
	client.poll()

	# Once connected, send a variable and then stop processing.
	if client.get_status() == StreamPeerTCP.STATUS_CONNECTED and not has_sent:
		print("Successfully connected to server!")
		send_variable_to_server(99)
		has_sent = true # Set the flag to true after sending.
		set_process(false)
		# We removed set_process(false) to keep the connection alive.
		# The client will now continue running until you manually stop it.

func send_variable_to_server(value: int):
	"""Sends a single integer variable to the server."""
	if client.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		print("Cannot send data, not connected.")
		return
		
	# Convert the integer to a PackedByteArray for sending.
	var data_to_send = PackedByteArray()
	data_to_send.encode_s64(0, value)
	
	# Send the data.
	var error = client.put_data(data_to_send)
	if error == OK:
		print("Sent variable '%d' to the server." % value)
	else:
		print("Error sending data: ", error)
