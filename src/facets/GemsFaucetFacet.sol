// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {GemsFacet} from "../facets/GemsFacet.sol";
import {LibGems} from "../libraries/LibGems.sol";
import {LibContractOwner} from "../../lib/cu-osc-diamond-template/src/libraries/LibContractOwner.sol";

import {LibTestnetDebugInterface} from "../../lib/cu-osc-common/src/libraries/LibTestnetDebugInterface.sol";
import {LibGemsFaucet} from "../libraries/LibGemsFaucet.sol";
import {LibResourceLocator} from "../../lib/cu-osc-common/src/libraries/LibResourceLocator.sol";

contract GemsFaucetFacet is GemsFacet {
    function faucetMint(
        address to,
        string calldata name,
        uint256[] calldata bonusesArray
    ) external {
        LibTestnetDebugInterface.enforceDebugger();

        require(
            bonusesArray.length == 18,
            "GemsFaucetFacet.faucetMint: bonusesArray should have length 18"
        );
        LibGems.GemsStorage storage gs = LibGems.gemsStorage();
        LibGemsFaucet.GemsFaucetStorage storage gfs = LibGemsFaucet
            .gemsFaucetStorage();
        gfs.lastMintedGemId++;
        uint256 nextTokenId = gfs.lastMintedGemId;
        require(
            !gs.gemMinted[nextTokenId],
            "GemsFaucetFacet.faucetMint: gem has previously been minted"
        );
        _mint(to, nextTokenId);

        gs.gemName[nextTokenId] = name;

        LibGems.mintBonuses(nextTokenId, bonusesArray);

        // Set gemMinted state on newly minted gem so that a gem with the same tokenId cannot be minted
        // again (even if this gem is burned).
        gs.gemMinted[nextTokenId] = true;
    }

    function faucetCloneGem(address to, uint256 gemIdToCopy) external {
        LibTestnetDebugInterface.enforceDebugger();

        LibGems.GemsStorage storage gs = LibGems.gemsStorage();
        require(
            gs.gemMinted[gemIdToCopy],
            "GemsFaucetFacet.faucetCloneGem: gem hasn't previously been minted"
        );
        LibGemsFaucet.gemsFaucetStorage().lastMintedGemId++;
        uint256 nextTokenId = LibGemsFaucet.gemsFaucetStorage().lastMintedGemId;
        _mint(to, nextTokenId);
        gs.gemName[nextTokenId] = gs.gemName[gemIdToCopy];
        gs.gemRarity[nextTokenId] = gs.gemRarity[gemIdToCopy];
        gs.gemBonuses[nextTokenId] = gs.gemBonuses[gemIdToCopy];
        gs.gemMinted[nextTokenId] = true;
    }

    function setFaucetLastMintedGem(uint256 lastMintedGemId) external {
        LibContractOwner.enforceIsContractOwner();
        LibGemsFaucet.gemsFaucetStorage().lastMintedGemId = lastMintedGemId;
    }

    function getFaucetLastMintedGem() external view returns (uint256) {
        return LibGemsFaucet.gemsFaucetStorage().lastMintedGemId;
    }
}
