//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IRedCat {

    function ownerOf(uint tokenId) external view returns (address);
    function getBuyTime(uint tokenId) external view returns (uint, uint);
    function getBan(uint tokenId) external view returns (uint, bool);
    function balanceOf(address owner) external view returns (uint256 balance);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

}