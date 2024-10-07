// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IPermissionProvider} from "../../lib/cu-osc-common/src/interfaces/IPermissionProvider.sol";
import {IDelegatePermissions} from "../../lib/cu-osc-common/src/interfaces/IDelegatePermissions.sol";
import {LibResourceLocator} from "../../lib/cu-osc-common/src/libraries/LibResourceLocator.sol";

/// @custom:storage-location erc7201:games.laguna.Gems.Permissions
library LibPermissions {
    // struct LibDelegationStorage {
    //     address permissionProvider;
    // }

    // bytes32 constant DELEGATION_STORAGE_POSITION =
    //     keccak256(abi.encode(uint256(keccak256('games.laguna.Gems.Permissions')) - 1)) & ~bytes32(uint256(0xff));

    // function delegationStorage() internal pure returns (LibDelegationStorage storage lhs) {
    //     bytes32 position = DELEGATION_STORAGE_POSITION;
    //     // solhint-disable-next-line no-inline-assembly
    //     assembly {
    //         lhs.slot := position
    //     }
    // }

    function getPermissionProvider()
        internal
        view
        returns (IDelegatePermissions)
    {
        return IDelegatePermissions(LibResourceLocator.playerProfile());
    }

    // pros: we reuse this function in every previous enforceCallerOwnsNFT.
    // cons: it's not generic
    function enforceCallerIsAccountOwnerOrHasPermissions(
        address delegator,
        IPermissionProvider.Permission[] memory permissions
    ) internal view {
        IDelegatePermissions pp = getPermissionProvider();

        //Sender is account owner or sender's delegator owns the assets and sender has specific permission for this action.
        require(
            delegator == msg.sender ||
                (delegator == pp.getDelegator(msg.sender) &&
                    pp.checkDelegatePermissions(delegator, permissions)),
            "LibPermissions: Must have permissions from delegator."
        );
    }

    function enforceCallerIsAccountOwnerOrHasPermission(
        address delegator,
        IPermissionProvider.Permission permission
    ) internal view {
        IDelegatePermissions pp = getPermissionProvider();

        //Sender is account owner or sender's delegator owns the assets and sender has specific permission for this action.
        require(
            delegator == msg.sender ||
                (pp.checkDelegatePermission(delegator, permission)),
            "LibPermissions: Must have permission from delegator."
        );
    }
}
