// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRentableNFT {
    function rentFrom(address _from, address _to, uint256 _id, uint256 _startTime, uint256 _endTime) external;

    function safeRentFrom(address _from, address _to, uint256 _id, uint256 _startTime, uint256 _endTime) external;

    function safeRentFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _startTime,
        uint256 _endTime,
        bytes calldata _data
    ) external;

    function extendLease(uint256 _id, uint256 _endTime) external;

    function getRenter(uint256 _id) external view returns (address);

    function getStartTime(uint256 _id) external view returns (uint256);

    function getEndTime(uint256 _id) external view returns (uint256);
}
