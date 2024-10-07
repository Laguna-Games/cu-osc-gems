// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/// @custom:storage-location erc7201:games.laguna.Gems.DevFaucet
library LibGemsFaucet {
    struct GemsFaucetStorage {
        uint256 lastMintedGemId;
        address debugRegistryAddress;
    }

    bytes32 constant GEMS_FAUCET_STORAGE_POSITION =
        keccak256(abi.encode(uint256(keccak256('games.laguna.Gems.DevFaucet')) - 1)) & ~bytes32(uint256(0xff));

    function gemsFaucetStorage() internal pure returns (GemsFaucetStorage storage gfs) {
        bytes32 position = GEMS_FAUCET_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            gfs.slot := position
        }
    }
}
