// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IRentableNFT} from "./interfaces/IRentableNFT.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";

abstract contract RentableNFT is IRentableNFT, ERC721 {
    struct Lease {
        address renter;
        uint256 startTime;
        uint256 endTime;
    }

    mapping(uint256 => Lease) private leases;

    event Rent(address indexed _from, address indexed _to, uint256 indexed _id, uint256 _startTime, uint256 _endTime);

    modifier rented(uint256 _id) {
        require(leases[_id].endTime <= block.timestamp, "NOT LEASED");
        _;
    }

    modifier notRented(uint256 _id) {
        require(leases[_id].endTime > block.timestamp, "LEASED");
        _;
    }

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function transferFrom(address _from, address _to, uint256 _id) public override notRented(_id) {
        super.transferFrom(_from, _to, _id);
    }

    function safeTransferFrom(address _from, address _to, uint256 _id) public override notRented(_id) {
        super.safeTransferFrom(_from, _to, _id);
    }

    function safeTransferFrom(address _from, address _to, uint256 _id, bytes calldata _data)
        public
        override
        notRented(_id)
    {
        super.safeTransferFrom(_from, _to, _id, _data);
    }

    function rentFrom(address _from, address _to, uint256 _id, uint256 _startTime, uint256 _endTime)
        public
        virtual
        notRented(_id)
    {
        require(_from == ownerOf(_id), "NOT OWNER");
        require(_to != address(0), "RENT TO ZERO ADDRESS");
        require(
            msg.sender == _from || isApprovedForAll[_from][msg.sender] || msg.sender == getApproved[_id],
            "NOT AUTHORIZED"
        );
        require(_startTime < _endTime, "INVALID TIME RANGE");
        require(_startTime >= block.timestamp, "INVALID START TIME");

        leases[_id] = Lease(_to, _startTime, _endTime);

        emit Rent(_from, _to, _id, _startTime, _endTime);
    }

    function safeRentFrom(address _from, address _to, uint256 _id, uint256 _startTime, uint256 _endTime)
        public
        virtual
    {
        rentFrom(_from, _to, _id, _startTime, _endTime);

        require(
            _to.code.length == 0
                || ERC721TokenRentee(_to).onERC721Rented(msg.sender, _from, _id, _startTime, _endTime, "")
                    == ERC721TokenRentee.onERC721Rented.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeRentFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _startTime,
        uint256 _endTime,
        bytes calldata _data
    ) public virtual {
        rentFrom(_from, _to, _id, _startTime, _endTime);

        require(
            _to.code.length == 0
                || ERC721TokenRentee(_to).onERC721Rented(msg.sender, _from, _id, _startTime, _endTime, _data)
                    == ERC721TokenRentee.onERC721Rented.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function extendLease(address _from, uint256 _id, uint256 _endTime) public rented(_id) {
        require(_from == ownerOf(_id), "NOT OWNER");
        require(
            msg.sender == _from || isApprovedForAll[_from][msg.sender] || msg.sender == getApproved[_id],
            "NOT AUTHORIZED"
        );
        require(_endTime > leases[_id].endTime, "INVALID END TIME");
        require(_endTime > block.timestamp, "INVALID END TIME");

        leases[_id].endTime = _endTime;
    }

    function getRenter(uint256 _id) public view returns (address) {
        if (leases[_id].endTime > block.timestamp) {
            return address(0);
        }
        return leases[_id].renter;
    }

    function getStartTime(uint256 _id) public view returns (uint256) {
        if (leases[_id].endTime > block.timestamp) {
            return 0;
        }
        return leases[_id].startTime;
    }

    function getEndTime(uint256 _id) public view returns (uint256) {
        if (leases[_id].endTime > block.timestamp) {
            return 0;
        }
        return leases[_id].endTime;
    }
}

abstract contract ERC721TokenRentee {
    function onERC721Rented(address, address, uint256, uint256, uint256, bytes calldata)
        external
        virtual
        returns (bytes4)
    {
        return ERC721TokenRentee.onERC721Rented.selector;
    }
}
