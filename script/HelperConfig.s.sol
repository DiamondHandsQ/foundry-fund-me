// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    // if we are on a local anvil, we deploy mocks
    // Otherwise, grab the existing address from the live netweork

    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed;
        string name;
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        // price feed address
        return NetworkConfig({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306, name: "Sepolia"});
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // price feed address

        // 1. Deploy the mocks to local anvil node if not already deployed
        // 2. Return the address of the mocks
        if (activeNetworkConfig.priceFeed == address(0)) {
            vm.startBroadcast();
            MockV3Aggregator mockV3Aggregator = new MockV3Aggregator(DECIMALS, INITIAL_PRICE); // 2000 USD to 8 decimals
            vm.stopBroadcast();

            return NetworkConfig({priceFeed: address(mockV3Aggregator), name: "Anvil"});
        } else {
            return activeNetworkConfig;
        }
    }
}
