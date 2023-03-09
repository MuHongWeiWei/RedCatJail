/**
This contract redemption has nothing to do with RMM's own team

Due to RMM's malicious lock-up of the holder's assets, the holder cannot live a normal life

With this, RedCat holders can temporarily use RedCat to borrow money
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import './Ownable.sol';
import "./IRedCat.sol";
import "./MerkleProof.sol";
import "./IERC721TokenReceiver.sol";
import "./ReentrancyGuard.sol";

struct RedCatInfo {
    address owner;
    uint borrowMoney;
    uint borrowTime;
    uint salePrice;
}

contract RedCatJail is Ownable, IERC721TokenReceiver, ReentrancyGuard {

    using MerkleProof for bytes32[];

    // constant
    IRedCat constant RedCat = IRedCat(0xddaAd340b0f1Ef65169Ae5E41A8b10776a75482d);

    // attributes
    bool public saleOpen = false;
    bool public borrowOpen = false;
    uint public borrowMoney = 0.2 ether;
    uint public redemptionTime = 90 days;
    uint public jailTime = 180 days;
    uint public holdTime = 60 days;
    bytes32 public merkleRoot;

    uint[] jailRedCat;
    uint[] abandonRedCat;
    mapping(uint tokenId => RedCatInfo) public jail;
    mapping(uint tokenId => RedCatInfo) public abandon;

    // event
    event VictimBorrowMoney(address borrower, uint borrowMoney, uint tokenId);
    event DepositMoney(address depositor, uint money);

    constructor() payable {
        emit DepositMoney(msg.sender, msg.value);
    }

    receive() external payable {
        emit DepositMoney(msg.sender, msg.value);
    }

    // 借錢
    function victimBorrowMoneyWhiteList(uint[] calldata tokenIds, bytes32[] calldata _proof) external nonReentrant {
        require(RedCat.balanceOf(msg.sender) - tokenIds.length >= 1, "hold at least one");
        require(verify(_proof), "address is not on the whitelist");
    
        for(uint i = 0; i < tokenIds.length; i++) {
            (uint tokenId, uint buyTime) = RedCat.getBuyTime(tokenIds[i]);
            (, bool ban) = RedCat.getBan(tokenIds[i]);
            
            require(block.timestamp - buyTime >= holdTime, "holding time too short");
            require(RedCat.ownerOf(tokenId) == msg.sender, "RedCat is not yours");
            require(!ban, "RedCat has been banned");

            RedCat.safeTransferFrom(msg.sender, address(this), tokenId);
            (bool success, ) = msg.sender.call{value: borrowMoney}("");
            require(success, "failed");

            jail[tokenId] = RedCatInfo(msg.sender, borrowMoney, block.timestamp, 0);
            jailRedCat.push(tokenId);
            emit VictimBorrowMoney(msg.sender, borrowMoney, tokenId);
        }
    }

    // 借錢
    function victimBorrowMoney(uint[] calldata tokenIds) external nonReentrant {
        require(RedCat.balanceOf(msg.sender) - tokenIds.length >= 1, "hold at least one");
    
        for(uint i = 0; i < tokenIds.length; i++) {
            (uint tokenId, uint buyTime) = RedCat.getBuyTime(tokenIds[i]);
            (, bool ban) = RedCat.getBan(tokenIds[i]);

            require(block.timestamp - buyTime >= holdTime, "holding time too short");
            require(RedCat.ownerOf(tokenId) == msg.sender, "RedCat is not yours");
            require(!ban, "RedCat has been banned");

            RedCat.safeTransferFrom(msg.sender, address(this), tokenId);
            (bool success, ) = msg.sender.call{value: borrowMoney}("");
            require(success, "failed");

            jail[tokenId] = RedCatInfo(msg.sender, borrowMoney, block.timestamp, 0);
            jailRedCat.push(tokenId);
            emit VictimBorrowMoney(msg.sender, borrowMoney, tokenId);
        }
    }

    // 贖回
    function redemptionRedCat() external payable {
        //判斷是否超過遺棄時間
        //買回去
        //算利息
    }

    // 購買
    function buyRedCat() external payable {
        require(saleOpen, "market not open");

    }

    // 確認拋棄
    function confirmAbandon() external {
        for(uint i = 0; i < jailRedCat.length; i++) {
            uint tokenId = jailRedCat[i];
            if(jail[tokenId].borrowTime >= jailTime) {
                abandon[tokenId] = jail[tokenId];
                abandonRedCat.push(tokenId);
                delete jail[tokenId];
            }
        }
    }

    // onlyOwner
    function setSalePrice(uint _tokenId, uint _price) external onlyOwner {
        abandon[_tokenId].salePrice = _price;
    }

    function setBorrowMoney(uint _borrowMoney) external onlyOwner {
        borrowMoney = _borrowMoney;
    }

    function setRedemptionTime(uint _redemptionTime) external onlyOwner {
        redemptionTime = _redemptionTime;
    }

    function setJailTime(uint _jailTime) external onlyOwner {
        jailTime = _jailTime;
    }

    function setHoldTime(uint _holdTime) external onlyOwner {
        holdTime = _holdTime;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdrawERC20(address _address, uint _amount) external onlyOwner {
        (bool success, ) = _address.call(abi.encodeWithSignature("transfer(address,uint256)", msg.sender, _amount));
        require(success, "failed");
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "failed");
    }

    // getter
    function getJailRedCat() external view returns(uint[] memory) {
        return jailRedCat;
    }

    function getAbandonRedCat() external view returns(uint[] memory) {
        return abandonRedCat;
    }

    function verify(bytes32[] calldata merkleProof) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return merkleProof.verify(merkleRoot, leaf);
    }

    function onERC721Received(address, address, uint, bytes calldata) external pure returns (bytes4) {
        return IERC721TokenReceiver.onERC721Received.selector;
    }

}