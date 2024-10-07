// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ISolidStateERC721} from '../../lib/@solidstate/contracts/token/ERC721/ISolidStateERC721.sol';

interface IGem is ISolidStateERC721 {
    // ### Note on multiplicative bonuses
    // Gems can have 1 - 3 affixes which provide multiplicative bonuses. All of these could apply
    // to the same stat.
    // The Gems contract only allows for the registration of a single multiplicative bonus.
    //
    // Suppose that a gem has three affixes, the first of which improves attack by x_1%, the second
    // of which improves attack by x_2%, and the third of which improves attack by x_3%.
    //
    // Then the attackMultiplicativeBonusPercent for that gem can is:
    // 100 * [(1 + x_1/100)*(1 + x_2/100)*(1 + x_3/100) - 1]
    //
    //  Multiplicative bonuses max out at 255%
    //  Additive bonuses max out at 65,535
    struct GemBonuses {
        uint16 attackAdditive;
        uint8 attackMultiplicativePercent;
        uint16 defenseAdditive;
        uint8 defenseMultiplicativePercent;
        uint16 vitalityAdditive;
        uint8 vitalityMultiplicativePercent;
        uint16 accuracyAdditive;
        uint8 accuracyMultiplicativePercent;
        uint16 magicAdditive;
        uint8 magicMultiplicativePercent;
        uint16 resistanceAdditive;
        uint8 resistanceMultiplicativePercent;
        uint16 attackSpeedAdditive;
        uint8 attackSpeedMultiplicativePercent;
        uint16 moveSpeedAdditive;
        uint8 moveSpeedMultiplicativePercent;
        uint8 numBonuses;
    }

    /// @notice Returns true if the gem with the given tokenId has been minted.
    /// @param tokenId The ID of the gem to check.
    function gemMinted(uint256 tokenId) external view returns (bool);

    /// @notice Returns the name of the gem with the given tokenId.
    /// @param tokenId The ID of the gem to check.
    function gemName(uint256 tokenId) external view returns (string memory);

    /// @notice Returns the rarity of the gem with the given tokenId.
    /// @param tokenId The ID of the gem to check.
    function gemRarity(uint256 tokenId) external view returns (uint256);

    /// @notice Returns the number of bonuses of the gem with the given tokenId.
    /// @param tokenId The ID of the gem to check.
    function gemNumBonuses(uint256 tokenId) external view returns (uint256);

    /// @notice Returns the type of the gem with the given tokenId.
    /// @param tokenId The ID of the gem to check.
    function gemType(uint256 tokenId) external view returns (string memory);

    /// @notice Returns the bonuses of the gem with the given tokenId.
    /// @param tokenId The ID of the gem to check.
    function bonuses(uint256 tokenId) external view returns (GemBonuses memory bonuses);

    /// @notice Returns the metadata of the gem with the given tokenId.
    /// @param tokenId The ID of the gem to check.
    function metadataJSON(uint256 tokenId) external view returns (string memory);
}
