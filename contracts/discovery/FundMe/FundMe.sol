// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter{
    function getPrice() internal view returns (uint256) {
  
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF
        );
        (
            ,
            /* uint80 roundId */
            int256 price,
            ,
            /*uint256 startedAt*/
            ,
            /*uint256 updatedAt*/

        ) = /*uint80 answeredInRound*/
            priceFeed.latestRoundData();

        return uint256(price * 1e10);
    }

    function getConversionRate(uint256 ethAmount) internal view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }

    function getVersion() internal view returns (uint256){
        return AggregatorV3Interface(0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF).version();
    }

}

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    uint256 public constant MINIMUM_USD = 5e18;

    address[] public funders;
    mapping(address funder => uint256 amountFunded) public addressToAmoutFounded;

    address public immutable i_owner;

    constructor() {
        i_owner = msg.sender;
    }

    function fund() public payable {
        require(msg.value.getConversionRate() >= MINIMUM_USD, "didn't send enough ETH"); // 1e18 = 1 ETH = 1000000000000000000 wei
        funders.push(msg.sender);
        addressToAmoutFounded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for(uint256 i = 0; i < funders.length; i++){
            address funder = funders[i];
            addressToAmoutFounded[funder] = 0;
        }

        funders = new address[](0);
        
        // https://solidity-by-example.org/sending-ether/
        
        //transfer
        // payable(msg.sender).transfer(address(this).balance);

        //send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        //call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not the owner!");
        if(msg.sender != i_owner) { revert NotOwner();}
        _;
    }

    receive() external payable { 
        fund();
    }

    fallback() external payable {
        fund();
     }
}