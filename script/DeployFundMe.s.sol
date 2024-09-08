// SPDX-LICENSE-Identifier
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

import {FundMe} from "../src/FundMe.sol";
import {MockV3Aggregator} from "../test/mock/MockV3Aggregator.t.sol";

contract DeployFundMe is Script {
    MockV3Aggregator mockV3Aggregator;

    function run() external returns (FundMe) {
        // The next line runs before the vm.startBroadcast() is called
        // This will not be deployed because the `real` signed txs are happening
        // between the start and stop Broadcast lines.
        HelperConfig helperConfig = new HelperConfig();
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        FundMe fundMe = new FundMe(address(0x694AA1769357215DE4FAC081bf1f309aDC325306));
        vm.stopBroadcast();
        return fundMe;
    }
}
