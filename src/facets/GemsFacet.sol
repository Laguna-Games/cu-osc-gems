// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {DiamondReentrancyGuard} from "../../lib/web3/contracts/diamond/security/DiamondReentrancyGuard.sol";
import {LibSignatures} from "../../lib/web3/contracts/diamond/libraries/LibSignatures.sol";
import {SignatureChecker} from "../../lib/openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol";
import {SolidStateERC721} from "../../lib/@solidstate/contracts/token/ERC721/SolidStateERC721.sol";
import {ERC721MetadataStorage} from "../../lib/@solidstate/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol";
import {ERC721BaseStorage} from "../../lib/@solidstate/contracts/token/ERC721/base/ERC721BaseStorage.sol";
import {EnumerableSet} from "../../lib/@solidstate/contracts/data/EnumerableSet.sol";

import {IERC721Metadata} from "../../lib/@solidstate/contracts/token/ERC721/metadata/IERC721Metadata.sol";
import {ERC721Metadata} from "../../lib/@solidstate/contracts/token/ERC721/metadata/ERC721Metadata.sol";

import {LibGems} from "../libraries/LibGems.sol";
import {LibContractOwner} from "../../lib/cu-osc-diamond-template/src/libraries/LibContractOwner.sol";
import {LibPermissions} from "../libraries/LibPermissions.sol";
import {IGem} from "../interfaces/IGem.sol";
import {LibEvents} from "../libraries/LibEvents.sol";

import {IPermissionProvider} from "../../lib/cu-osc-common/src/interfaces/IPermissionProvider.sol";
import {IDelegatePermissions} from "../../lib/cu-osc-common/src/interfaces/IDelegatePermissions.sol";
import {LibResourceLocator} from "../../lib/cu-osc-common/src/libraries/LibResourceLocator.sol";
import {LibEnvironment} from "../../lib/cu-osc-common/src/libraries/LibEnvironment.sol";

import {LibGasReturner} from "../../lib/cu-osc-common/src/libraries/LibGasReturner.sol";

// GemsFacet implements the ERC721 functionality for Crypto Unicorns Gems, as well as all related
// operations (such as minting with authorized signature).
contract GemsFacet is IGem, SolidStateERC721, DiamondReentrancyGuard {
    string public gemsVersion = "0.2.0";

    // This function is intended for use when attaching the GemsFacet to a Crypto Unicorns Gems diamond
    // contract. It can also be used to change the metadata.
    function initGems(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address adminTerminusAddress,
        uint256 adminTerminusPoolID
    ) public {
        LibContractOwner.enforceIsContractOwner();

        ERC721MetadataStorage.Layout storage s = ERC721MetadataStorage.layout();
        s.name = name;
        s.symbol = symbol;
        s.baseURI = baseURI;

        LibSignatures._setEIP712Parameters("Crypto Unicorns Gems", gemsVersion);

        LibGems.setAdminTerminusPool(adminTerminusAddress, adminTerminusPoolID);
    }

    /**
     * @dev See https://docs.opensea.io/docs/contract-level-metadata
     */
    function contractURI() public view returns (string memory) {
        return ERC721MetadataStorage.layout().baseURI;
    }

    function adminTerminusInfo() external view returns (address, uint256) {
        LibGems.GemsStorage storage gs = LibGems.gemsStorage();
        return (gs.adminTerminusAddress, gs.adminTerminusPoolID);
    }

    // Only the Diamond contract owner can change the Terminus pool defining the administrators of this
    // Gems contract.
    function changeAdminTerminusInfo(
        address adminTerminusAddress,
        uint256 adminTerminusPoolID
    ) external {
        LibContractOwner.enforceIsContractOwner();
        LibGems.setAdminTerminusPool(adminTerminusAddress, adminTerminusPoolID);
    }

    function mintMessageHash(
        address to,
        uint256 tokenId,
        string calldata name,
        uint256[] calldata bonusesArray,
        uint256 requestId,
        uint256 blockDeadline
    ) public view virtual returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "MintPayload(address to,uint256 tokenId,string name,uint256[] bonusesArray,uint256 requestId,uint256 blockDeadline)"
                ),
                to,
                tokenId,
                keccak256(bytes(name)),
                keccak256(abi.encodePacked(bonusesArray)),
                requestId,
                blockDeadline
            )
        );
        bytes32 digest = LibSignatures._hashTypedDataV4(structHash);
        return digest;
    }

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
    ) public virtual diamondNonReentrant {
        uint256 availableGas = gasleft();
        // bonusesArray is assumed to have the following structure:
        // [
        //   rarity,
        //   numBonuses,
        //   attackAdditive,
        //   attackMultiplicativePercent,
        //   defenseAdditive,
        //   defenseMultiplicativePercent,
        //   vitalityAdditive,
        //   vitalityMultiplicativePercent,
        //   accuracyAdditive,
        //   accuracyMultiplicativePercent,
        //   magicAdditive,
        //   magicMultiplicativePercent,
        //   resistanceAdditive,
        //   resistanceMultiplicativePercent,
        //   attackSpeedAdditive,
        //   attackSpeedMultiplicativePercent,
        //   moveSpeedAdditive,
        //   moveSpeedMultiplicativePercent
        // ]
        require(
            bonusesArray.length == 18,
            "GemsFacet.mint: bonusesArray should have length 18"
        );

        // LibGems.GemsStorage storage gs = ;
        require(
            !LibGems.gemsStorage().gemMinted[tokenId],
            "GemsFacet.mint: gem has previously been minted"
        );

        require(
            LibEnvironment.getBlockNumber() <= blockDeadline,
            "GemsFacet.mint: signature expired"
        );
        require(
            LibGems.isAdmin(signer),
            "GemsFacet.mint: signer is not an administrator"
        );

        bytes32 hash = mintMessageHash(
            to,
            tokenId,
            name,
            bonusesArray,
            requestId,
            blockDeadline
        );
        require(
            SignatureChecker.isValidSignatureNow(signer, hash, signature),
            "GemsFacet.mint: invalid signature"
        );

        LibPermissions.enforceCallerIsAccountOwnerOrHasPermission(
            to,
            IPermissionProvider.Permission.GEM_MINT_ALLOWED
        );

        _mint(to, tokenId);

        LibGems.finishMintGem(
            to,
            tokenId,
            name,
            bonusesArray,
            signer,
            requestId
        );

        LibGasReturner.returnGasToUser(
            "mintWithSignature",
            (availableGas - gasleft()),
            payable(msg.sender)
        );
    }

    function gemMinted(uint256 tokenId) external view returns (bool) {
        return LibGems.gemsStorage().gemMinted[tokenId];
    }

    function burn(uint256 tokenId) external diamondNonReentrant {
        require(
            msg.sender == _ownerOf(tokenId),
            "GemsFacet.burn: caller is not token owner"
        );
        _burn(tokenId);
    }

    function gemName(uint256 tokenId) external view returns (string memory) {
        return LibGems.gemsStorage().gemName[tokenId];
    }

    function gemRarity(uint256 tokenId) external view returns (uint256) {
        return LibGems.gemsStorage().gemRarity[tokenId];
    }

    function gemNumBonuses(uint256 tokenId) external view returns (uint256) {
        return LibGems.gemsStorage().gemBonuses[tokenId].numBonuses;
    }

    function gemType(uint256 tokenId) external view returns (string memory) {
        return LibGems.gemType(tokenId);
    }

    function bonuses(
        uint256 tokenId
    ) external view returns (IGem.GemBonuses memory gemBonuses) {
        gemBonuses = LibGems.gemsStorage().gemBonuses[tokenId];
    }

    function metadataJSON(
        uint256 tokenId
    ) external view returns (string memory) {
        return string(LibGems.generateJSONBytes(tokenId));
    }

    function tokenURI(
        uint256 tokenId
    )
        external
        view
        override(ERC721Metadata, IERC721Metadata)
        returns (string memory)
    {
        return LibGems.generateTokenURI(tokenId);
    }

    function transferToUnicornContract(
        uint256[] calldata tokenIds
    ) external diamondNonReentrant {
        //  NOTE - we are relying on the Unicorn contract to check that the
        //  original caller is either the owner of delegate-with-permission of
        //  the Gem NFTs being transferred - we can't enforce that here without
        //  knowing the msg.sender of the unicorn.equip call.
        address unicornNFTAddress = LibResourceLocator.unicornNFT();
        require(
            msg.sender == unicornNFTAddress,
            "Only allowed by Unicorn contract"
        );
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _safeTransfer(
                _ownerOf(tokenIds[i]),
                unicornNFTAddress,
                tokenIds[i],
                ""
            );
        }
    }

    function getAllGemsByOwner(
        address _owner,
        uint32 _pageNumber
    ) external view returns (uint256[] memory tokenIds, bool moreEntriesExist) {
        EnumerableSet.UintSet storage tokens = ERC721BaseStorage
            .layout()
            .holderTokens[_owner];
        uint256 balance = EnumerableSet.length(tokens);
        uint start = _pageNumber * 12;
        uint count = balance - start;
        if (count > 12) {
            count = 12;
            moreEntriesExist = true;
        }

        tokenIds = new uint256[](count);

        for (uint i = 0; i < count; ++i) {
            uint256 indx = start + i;
            uint256 tokenId = EnumerableSet.at(tokens, indx);
            tokenIds[i] = tokenId;
        }
    }

    function getBaseImageUri() external view returns (string memory) {
        return LibGems.baseImageUri();
    }

    function setGemBaseImageUri(string calldata _baseImageUri) external {
        LibContractOwner.enforceIsContractOwner();
        LibGems.setBaseImageUri(_baseImageUri);
    }

    function license() external pure returns (string memory) {
        return "";
    }
}
