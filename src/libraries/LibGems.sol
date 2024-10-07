// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IERC1155} from "../../lib/openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import {Strings} from "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {ERC721MetadataStorage} from "../../lib/@solidstate/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol";
import {LibBase64} from "../../lib/cu-osc-common/src/libraries/LibBase64.sol";
import {IGem} from "../interfaces/IGem.sol";
import {LibEvents} from "./LibEvents.sol";

// LibGems implements the Diamond storage pattern for the Crypto Unicorns Gems contract.
// It also contains several internal methods which make it convenient to interact with Gems storage.
library LibGems {
    struct GemsStorage {
        address adminTerminusAddress;
        uint256 adminTerminusPoolID;
        // GemMinted is used to guarantee that the same gem cannot be minted twice, even if it was
        // burned between calls to mint.
        mapping(uint256 => bool) gemMinted;
        // Names
        mapping(uint256 => string) gemName;
        // Rarities
        mapping(uint256 => uint256) gemRarity;
        // Stat bonuses
        mapping(uint256 tokenId => IGem.GemBonuses bonuses) gemBonuses;
        string baseImageUri;
    }

    bytes32 private constant GEMS_STORAGE_POSITION =
        keccak256("CryptoUnicorns.Gems.storage");

    function gemsStorage() internal pure returns (GemsStorage storage gs) {
        bytes32 position = GEMS_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            gs.slot := position
        }
    }

    function setBaseImageUri(string memory _baseImageUri) internal {
        gemsStorage().baseImageUri = _baseImageUri;
    }

    function baseImageUri() internal view returns (string memory) {
        return gemsStorage().baseImageUri;
    }

    function setAdminTerminusPool(
        address adminTerminusAddress,
        uint256 adminTerminusPoolID
    ) internal {
        GemsStorage storage gs = gemsStorage();
        gs.adminTerminusAddress = adminTerminusAddress;
        gs.adminTerminusPoolID = adminTerminusPoolID;
    }

    function isAdmin(address account) internal view returns (bool) {
        GemsStorage storage gs = gemsStorage();
        IERC1155 adminTerminus = IERC1155(gs.adminTerminusAddress);
        return (adminTerminus.balanceOf(account, gs.adminTerminusPoolID) > 0);
    }

    function gemType(uint256 tokenId) internal view returns (string memory) {
        IGem.GemBonuses memory b = gemsStorage().gemBonuses[tokenId];
        if (b.attackAdditive > 0) {
            return "attack";
        } else if (b.accuracyAdditive > 0) {
            return "accuracy";
        } else if (b.moveSpeedAdditive > 0) {
            return "move_speed";
        } else if (b.attackSpeedAdditive > 0) {
            return "attack_speed";
        } else if (b.defenseAdditive > 0) {
            return "defense";
        } else if (b.vitalityAdditive > 0) {
            return "vitality";
        } else if (b.resistanceAdditive > 0) {
            return "resistance";
        } else if (b.magicAdditive > 0) {
            return "magic";
        }
    }

    function gemImagePrefix(
        uint256 tokenId
    ) internal view returns (string memory) {
        IGem.GemBonuses memory b = gemsStorage().gemBonuses[tokenId];
        if (b.attackAdditive > 0) {
            return "attack";
        } else if (b.accuracyAdditive > 0) {
            return "accuracy";
        } else if (b.moveSpeedAdditive > 0) {
            return "movementspeed";
        } else if (b.attackSpeedAdditive > 0) {
            return "attackspeed";
        } else if (b.defenseAdditive > 0) {
            return "defense";
        } else if (b.vitalityAdditive > 0) {
            return "vitality";
        } else if (b.resistanceAdditive > 0) {
            return "resistance";
        } else if (b.magicAdditive > 0) {
            return "magic";
        }
    }

    function finishMintGem(
        address to,
        uint256 tokenId,
        string memory name,
        uint256[] memory bonusesArray,
        address signer,
        uint256 requestId
    ) internal {
        gemsStorage().gemName[tokenId] = name;

        mintBonuses(tokenId, bonusesArray);

        // Set gemMinted state on newly minted gem so that a gem with the same tokenId cannot be minted
        // again (even if this gem is burned).
        gemsStorage().gemMinted[tokenId] = true;

        emit LibEvents.GemCreated(
            requestId,
            tokenId,
            to,
            name,
            signer,
            bonusesArray
        );
    }

    function gemImageURL(
        uint256 tokenId
    ) internal view returns (string memory) {
        GemsStorage storage gs = gemsStorage();
        string memory gemTypeString;
        gemTypeString = gemImagePrefix(tokenId);
        return
            string(
                abi.encodePacked(
                    baseImageUri(),
                    "/",
                    gemTypeString,
                    "_t",
                    Strings.toString(gs.gemRarity[tokenId]),
                    "_b",
                    Strings.toString(gs.gemBonuses[tokenId].numBonuses),
                    "_nft.png"
                )
            );
    }

    function generateJSONBytes(
        uint256 tokenId
    ) internal view returns (bytes memory) {
        GemsStorage storage gs = gemsStorage();
        IGem.GemBonuses memory b = gs.gemBonuses[tokenId];

        // TODO: Refactor all of this to use string.concat()

        // Creating json in chunked to avoid stack depth issue.
        bytes memory json = abi.encodePacked(
            '{"token_id":"',
            Strings.toString(tokenId),
            '", "name":"',
            gs.gemName[tokenId],
            '", "external_url":"https://www.cryptounicorns.fun","metadata_version":1'
        );

        json = abi.encodePacked(
            json,
            ',"image":"',
            gemImageURL(tokenId),
            '","attributes":[',
            '{"trait_type":"rarity","value":"',
            Strings.toString(gs.gemRarity[tokenId]),
            '"}',
            ',{"trait_type":"gem_type","value":"',
            gemType(tokenId),
            '"}'
        );

        json = abi.encodePacked(
            json,
            ',{"trait_type":"additive_attack_bonus","value":"',
            Strings.toString(b.attackAdditive),
            '"}',
            ',{"trait_type":"multiplicative_attack_bonus","value":"',
            Strings.toString(b.attackMultiplicativePercent),
            '"}',
            ',{"trait_type":"additive_defense_bonus","value":"',
            Strings.toString(b.defenseAdditive),
            '"}',
            ',{"trait_type":"multiplicative_defense_bonus","value":"',
            Strings.toString(b.defenseMultiplicativePercent),
            '"}'
        );

        json = abi.encodePacked(
            json,
            ',{"trait_type":"additive_vitality_bonus","value":"',
            Strings.toString(b.vitalityAdditive),
            '"}',
            ',{"trait_type":"multiplicative_vitality_bonus","value":"',
            Strings.toString(b.vitalityMultiplicativePercent),
            '"}',
            ',{"trait_type":"additive_accuracy_bonus","value":"',
            Strings.toString(b.accuracyAdditive),
            '"}',
            ',{"trait_type":"multiplicative_accuracy_bonus","value":"',
            Strings.toString(b.accuracyMultiplicativePercent),
            '"}'
        );

        json = abi.encodePacked(
            json,
            ',{"trait_type":"additive_magic_bonus","value":"',
            Strings.toString(b.magicAdditive),
            '"}',
            ',{"trait_type":"multiplicative_magic_bonus","value":"',
            Strings.toString(b.magicMultiplicativePercent),
            '"}',
            ',{"trait_type":"additive_resistance_bonus","value":"',
            Strings.toString(b.resistanceAdditive),
            '"}',
            ',{"trait_type":"multiplicative_resistance_bonus","value":"',
            Strings.toString(b.resistanceMultiplicativePercent),
            '"}'
        );

        json = abi.encodePacked(
            json,
            ',{"trait_type":"additive_attack_speed_bonus","value":"',
            Strings.toString(b.attackSpeedAdditive),
            '"}',
            ',{"trait_type":"multiplicative_attack_speed_bonus","value":"',
            Strings.toString(b.attackSpeedMultiplicativePercent),
            '"}',
            ',{"trait_type":"additive_move_speed_bonus","value":"',
            Strings.toString(b.moveSpeedAdditive),
            '"}',
            ',{"trait_type":"multiplicative_move_speed_bonus","value":"',
            Strings.toString(b.moveSpeedMultiplicativePercent),
            '"}',
            ',{"trait_type":"bonuses_no","value":"',
            Strings.toString(b.numBonuses),
            '"}',
            "]}"
        );

        return json;
    }

    function generateTokenURI(
        uint256 tokenId
    ) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    LibBase64.encode(generateJSONBytes(tokenId))
                )
            );
    }

    function mintBonuses(
        uint256 tokenId,
        uint256[] memory bonusesArray
    ) internal {
        GemsStorage storage gs = gemsStorage();
        gs.gemRarity[tokenId] = bonusesArray[0];
        gs.gemBonuses[tokenId] = IGem.GemBonuses(
            uint16(bonusesArray[2]), // attackAdditive
            uint8(bonusesArray[3]), // attackMultiplicativePercent
            uint16(bonusesArray[4]), // defenseAdditive
            uint8(bonusesArray[5]), // defenseMultiplicativePercent
            uint16(bonusesArray[6]), // vitalityAdditive
            uint8(bonusesArray[7]), // vitalityMultiplicativePercent
            uint16(bonusesArray[8]), // accuracyAdditive
            uint8(bonusesArray[9]), // accuracyMultiplicativePercent
            uint16(bonusesArray[10]), // magicAdditive
            uint8(bonusesArray[11]), // magicMultiplicativePercent
            uint16(bonusesArray[12]), // resistanceAdditive
            uint8(bonusesArray[13]), // resistanceMultiplicativePercent
            uint16(bonusesArray[14]), // attackSpeedAdditive
            uint8(bonusesArray[15]), // attackSpeedMultiplicativePercent
            uint16(bonusesArray[16]), // moveSpeedAdditive
            uint8(bonusesArray[17]), // moveSpeedMultiplicativePercent
            uint8(bonusesArray[1]) // numBonuses
        );
    }
}
