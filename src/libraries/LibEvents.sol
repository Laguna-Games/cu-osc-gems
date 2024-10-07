// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

library LibEvents {
    event GemCreated(
        uint256 indexed requestId,
        uint256 indexed tokenId,
        address owner,
        string name,
        address indexed signer,
        uint256[] parameters
    );
}
