// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./StringBuilderLib.sol";
import "./PathLib.sol";

contract MetadataGenerator is Ownable {
	struct Color {
		string name;
		string value;
	}

    struct Body {
        string name;
        bytes path;
		uint256 destlen;
    }

	struct Face {
        string name;
        bytes path;
		uint256 destlen;
    }

    mapping(uint8 => Color) public colors;
    mapping(uint8 => Body) public bodies;
    mapping(uint8 => Face) public faces;
	
	string public externalUrlPrefix;

	constructor(string memory _externalUrlPrefix) {
		externalUrlPrefix = _externalUrlPrefix;
	}

	function setColors(
		uint8[] calldata ids,
		string[] calldata names,
		string[] calldata values
	) external onlyOwner {
		for (uint256 i = 0; i < ids.length; i++) {
			colors[ids[i]] = Color({
				name: names[i], 
				value: values[i]
			});
		}
	}

    function setBodies(
		uint8[] calldata ids,
		string[] calldata names,
		bytes[] calldata paths,
		uint256[] calldata destlens
	) external onlyOwner {
		for (uint i = 0; i < ids.length; i++) {
			bodies[ids[i]] = Body({ 
				name: names[i], 
				path: paths[i],
				destlen: destlens[i]
			});
		}
    }

    function setFaces(
		uint8[] calldata ids,
		string[] calldata names,
		bytes[] calldata paths,
		uint256[] calldata destlens
	) external onlyOwner {
		for (uint i = 0; i < ids.length; i++) {
			faces[ids[i]] = Face({ 
				name: names[i], 
				path: paths[i],
				destlen: destlens[i]
			});
		}
    }

	function setExternalUrlPrefix(string memory _externalUrlPrefix) external onlyOwner {
		externalUrlPrefix = _externalUrlPrefix;
	}

	function generateMetadata(uint256 tokenId) external view returns (string memory) {
		(uint8 colorId, uint8 bodyId, uint8 faceId) = splitTokenId(tokenId);
		
		Color memory color = colors[colorId];
		Body memory body = bodies[bodyId];
		Face memory face = faces[faceId];

		// 341 is the size of the other text for the svg.
		uint256 buffSize = 341 + body.destlen + face.destlen;
		StringBuilderLib.StringBuilder memory stringBuilder = StringBuilderLib.newStringBuilder(buffSize);
		generateSvg(stringBuilder, color.value, body.path, face.path);
		bytes memory svg = StringBuilderLib.toBytes(stringBuilder);

		string memory tokenIdString = Strings.toString(tokenId);
		
		return string(abi.encodePacked("data:application/json;base64,", Base64.encode(abi.encodePacked(
			"{\"image\":\"data:image/svg+xml;base64,", Base64.encode(svg),
			"\",\"name\":\"Buddy #", tokenIdString,
			"\",\"external_url\":\"", externalUrlPrefix, tokenIdString,
			"\",\"attributes\":[{\"trait_type\":\"Color\",\"value\":\"", color.name, 
			"\"},{\"trait_type\":\"Body\",\"value\":\"", body.name, 
			"\"},{\"trait_type\":\"Face\",\"value\":\"", face.name, 
			"\"}]}"
		))));
	}

	function splitTokenId(uint256 tokenId) private pure returns (uint8, uint8, uint8) {
		require(tokenId < 1000);
		uint256 color = tokenId / 100;
		tokenId = tokenId - (color * 100);
		uint256 body = tokenId / 10;
		uint256 face = tokenId - (body * 10);
		return (uint8(color), uint8(body), uint8(face));
	}

	function generateSvg(
		StringBuilderLib.StringBuilder memory stringBuilder,
		string memory _color,
		bytes memory _body,
		bytes memory _face
	) private pure {
		StringBuilderLib.writeString(stringBuilder, "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?><svg width=\"1e3\" height=\"1e3\" viewBox=\"0 0 1e3 1e3\" version=\"1.1\" id=\"svg115\" xml:space=\"preserve\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:svg=\"http://www.w3.org/2000/svg\">");
       	writeSvgPath(stringBuilder, "body", _color, _body);
       	writeSvgPath(stringBuilder, "face", "000000", _face);
       	StringBuilderLib.writeString(stringBuilder, "</svg>");
	}

	function writeSvgPath(
		StringBuilderLib.StringBuilder memory stringBuilder,
		string memory id,
		string memory color,
		bytes memory path
	) private pure {
		StringBuilderLib.writeString(stringBuilder, "<path id=\"");
		StringBuilderLib.writeString(stringBuilder, id);
		StringBuilderLib.writeString(stringBuilder, "\" d=\"");
		PathLib.decodePath(stringBuilder, path);
		StringBuilderLib.writeString(stringBuilder, "\" fill=\"#");
		StringBuilderLib.writeString(stringBuilder, color);
		StringBuilderLib.writeString(stringBuilder, "\" stroke=\"#");
		StringBuilderLib.writeString(stringBuilder, color);
		StringBuilderLib.writeString(stringBuilder, "\" />");
	}
}
