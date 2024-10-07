// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CutERC721Diamond} from "../../lib/cu-osc-common-tokens/src/implementation/CutERC721Diamond.sol";
import {IGem} from "../interfaces/IGem.sol";

/// @title Dummy "implementation" contract for LG Diamond interface for ERC-1967 compatibility
/// @dev adapted from https://github.com/zdenham/diamond-etherscan?tab=readme-ov-file
/// @dev This interface is used internally to call endpoints on a deployed diamond cluster.
contract GemsImplementation is CutERC721Diamond {
    event GemCreated(
        uint256 indexed requestId,
        uint256 indexed tokenId,
        address owner,
        string name,
        address indexed signer,
        uint256[] parameters
    );

    function adminTerminusInfo() external view returns (address, uint256) {}

    function changeAdminTerminusInfo(
        address adminTerminusAddress,
        uint256 adminTerminusPoolID
    ) external {}

    function getAllGemsByOwner(
        address _owner,
        uint32 _pageNumber
    )
        external
        view
        returns (uint256[] memory tokenIds, bool moreEntriesExist)
    {}

    function mintMessageHash(
        address to,
        uint256 tokenId,
        string calldata name,
        uint256[] calldata bonusesArray,
        uint256 requestId,
        uint256 blockDeadline
    ) public view virtual returns (bytes32) {}

    function mintWithSignature(
        // requestId is not used as part of any idempotence logic - users will not be able to mint a gem that
        // was already minted anyway - the tokenId enforce all constraints.
        // requestId is simply used so that the gamer server can track the completion of signed workflows.
        // It *is* an indexed field of the GemCreated event.
        address to,
        uint256 tokenId,
        string calldata name,
        uint256[] calldata bonusesArray,
        address signer,
        uint256 requestId,
        uint256 blockDeadline,
        bytes calldata signature
    ) public {}

    function transferToUnicornContract(uint256[] calldata tokenIds) external {}

    /// @notice Returns true if the gem with the given tokenId has been minted.
    /// @param tokenId The ID of the gem to check.
    function gemMinted(uint256 tokenId) external view returns (bool) {}

    /// @notice Returns the name of the gem with the given tokenId.
    /// @param tokenId The ID of the gem to check.
    function gemName(uint256 tokenId) external view returns (string memory) {}

    /// @notice Returns the rarity of the gem with the given tokenId.
    /// @param tokenId The ID of the gem to check.
    function gemRarity(uint256 tokenId) external view returns (uint256) {}

    /// @notice Returns the number of bonuses of the gem with the given tokenId.
    /// @param tokenId The ID of the gem to check.
    function gemNumBonuses(uint256 tokenId) external view returns (uint256) {}

    /// @notice Returns the type of the gem with the given tokenId.
    /// @param tokenId The ID of the gem to check.
    function gemType(uint256 tokenId) external view returns (string memory) {}

    /// @notice Returns the bonuses of the gem with the given tokenId.
    /// @param tokenId The ID of the gem to check.
    function bonuses(
        uint256 tokenId
    ) external view returns (IGem.GemBonuses memory) {}

    /// @notice Returns the metadata of the gem with the given tokenId.
    /// @param tokenId The ID of the gem to check.
    function metadataJSON(
        uint256 tokenId
    ) external view returns (string memory) {}
}
