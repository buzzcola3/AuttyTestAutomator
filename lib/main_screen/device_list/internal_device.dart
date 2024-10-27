

String startNodeIcon = """
<?xml version="1.0" encoding="utf-8"?>

<!-- Uploaded to: SVG Repo, www.svgrepo.com, Generator: SVG Repo Mixer Tools -->
<svg version="1.1" id="Uploaded to svgrepo.com" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" 
	 width="800px" height="800px" viewBox="0 0 32 32" xml:space="preserve">
<style type="text/css">
	.hatch_een{fill:#265AA5;}
	.hatch_twee{fill:#FFC5BB;}
</style>
<g>
	<path class="hatch_twee" d="M18.157,12.714l0.905,0.509L8,24.285v-1.414L18.157,12.714z M12.277,22.594l3.232-1.818l6.114-6.114
		l-0.905-0.509L12.277,22.594z M24,16l-0.723-0.406l-1.858,1.858L24,16z M8,14.871v1.414l5.942-5.942l-0.905-0.509L8,14.871z
		 M8,8.285l0.822-0.822L8,7V8.285z M8,18.871v1.414l8.502-8.502l-0.905-0.509L8,18.871z M8,10.871v1.414l3.382-3.382l-0.905-0.509
		L8,10.871z"/>
	<path class="hatch_een" d="M24,16L8,25V7L24,16z M7.495,6.137C7.188,6.316,7,6.614,7,7v18c0,0.355,0.188,0.684,0.495,0.863
		C7.651,25.954,7.825,26,8,26c0.169,0,0.338-0.043,0.49-0.128l16-9C24.805,16.694,25,16.361,25,16c0-0.361-0.195-0.694-0.51-0.872
		l-16-9C8.338,6.043,8.18,6,8,6S7.651,6.046,7.495,6.137z"/>
</g>
</svg>
""";

Map<String, dynamic> internalDevice = {
  "DEVICE_NAME": "Functions",
  "UNIQUE_ID": "internal",
  "DEVICE_AVAILABLE_COMMANDS": [],
  "DEVICE_AVAILABLE_NODES": [
    {
      "Name": "Start",
      "Type": "buttonNode",
      "Command": "RUN",
      "Parameters": [],
      "Color": "green",
      "InPorts": [],
      "OutPorts": ["start_outport"],
      "SvgIcon": startNodeIcon
    },
    {
      "Name": "Delay",
      "Type": "basicNode",
      "Command": "DELAY",
      "Parameters": 
      [
        {
          "Name": "Delay(ms)",
          "Type": "int",
          "Value": "1000",
        }
      ],
      "Color": "blue",
      "InPorts": ["delay_inport"],
      "OutPorts": ["delay_outport"],
      "SvgIcon": startNodeIcon
    }
  ],
};

Future<void> internalDeviceCommandProcessor(String command, List<dynamic> params) async {
  print(command);
  print(params);

  if(command == "DELAY"){
    await Future.delayed(Duration(milliseconds: int.parse(params[0])));
  }
}
