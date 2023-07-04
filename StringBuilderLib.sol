// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/Math.sol";

library StringBuilderLib {
	bytes16 private constant _SYMBOLS = "0123456789";

	struct StringBuilder {
		bytes buf;
		uint256 len;
	}

	function newStringBuilder(uint256 n) internal pure returns (StringBuilder memory) {
		return StringBuilder({
			buf: new bytes(n),
			len: 0
		});
	}

	function writeString(
		StringBuilder memory stringBuilder, 
		string memory s
	) internal pure {
		writeBytes(stringBuilder, bytes(s));
	}

	function writeBytes(
		StringBuilder memory stringBuilder, 
		bytes memory b
	) internal pure {
		uint256 len = stringBuilder.len;
		for (uint256 i = 0; i < b.length; i++) {
			stringBuilder.buf[len + i] = b[i];
		}
		stringBuilder.len += b.length;
	}

	function writeChar(
		StringBuilder memory stringBuilder, 
		string memory s
	) internal pure {
		stringBuilder.buf[stringBuilder.len] = bytes(s)[0];
		stringBuilder.len++;
	}

	// From @openzeppelin/contracts/utils/Strings.sol, modified to include a fixed point & write to stream.
	function writeFixed(
		StringBuilder memory stringBuilder, 
		uint256 value
	) internal pure {
		unchecked {
			bytes memory buf = stringBuilder.buf;
			uint256 len = stringBuilder.len;

			// @dev Add an additonal 1 for the fixed point
			uint256 length = Math.log10(value) + 1 + 1; 
			uint256 i = 0;
			uint256 ptr;
			/// @solidity memory-safe-assembly
			assembly {
				ptr := add(buf, add(add(len, 32), length))
			}
			while (true) {
				// @dev include the fixed point to account for div 100000
				if (i == 1) {
					ptr--;
					/// @solidity memory-safe-assembly
					assembly {
						mstore8(ptr, byte(0, "."))
					}
				}
				ptr--;
				/// @solidity memory-safe-assembly
				assembly {
					mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
				}
				value /= 10;
				if (value == 0) break;
				i += 1;
			}
			stringBuilder.len += length;
			// @dev loop back and decrement length to trim trailing zeros
			while (true) {
				bytes1 char = stringBuilder.buf[stringBuilder.len - 1];
				if (char == ".") {
					stringBuilder.len--;
					break;
				}
				if (char != "0") {
					break;
				}
				stringBuilder.len--;
			}
		}
	}

	function trimOne(StringBuilder memory stringBuilder) internal pure {
		stringBuilder.len--;
	}

	function toBytes(
		StringBuilder memory stringBuilder
	) internal pure returns (bytes memory) {
		bytes memory buf = stringBuilder.buf;
		uint256 len = stringBuilder.len;
		/// @solidity memory-safe-assembly
		assembly {
			mstore(buf, len)
		}
		return buf;
	}

	function toString(
		StringBuilder memory stringBuilder
	) internal pure returns (string memory) {
		return string(toBytes(stringBuilder));
	}
}
