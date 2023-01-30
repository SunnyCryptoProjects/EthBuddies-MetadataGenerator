// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./StringBuilderLib.sol";

library PathLib {
    function decodePath(
		StringBuilderLib.StringBuilder memory stringBuilder, 
		bytes memory path
	) internal pure {
        uint256 i = 0;
        while (i < path.length) {
            uint8 u = uint8(path[i]);
            if (u == 128) {
				StringBuilderLib.writeChar(stringBuilder, "M");
                i++;
            } else if (u == 129) {
				StringBuilderLib.writeChar(stringBuilder, "C");
                i++;
            } else if (u == 130) {
				StringBuilderLib.writeChar(stringBuilder, "Z");
                i++;
            } else {
				StringBuilderLib.writeFixed(stringBuilder, readUint16(path, i));
				i += 2;

				StringBuilderLib.writeChar(stringBuilder, ",");
				
				StringBuilderLib.writeFixed(stringBuilder, readUint16(path, i));
                i += 2;
            }
			StringBuilderLib.writeChar(stringBuilder, " ");
        }
		StringBuilderLib.trimOne(stringBuilder);
    }

    function readUint16(bytes memory b, uint start) private pure returns (uint16) {
        uint16 x;
        assembly {
            x := mload(add(b, add(0x02, start)))
        }
        return x;
    }
}
