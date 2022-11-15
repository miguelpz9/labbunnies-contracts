// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Ectoplasm20 is ERC20, Ownable {
    using SafeMath for uint256;

    address private mintingContract;
    uint256 minted = 0;
    uint256 hardCap = 500000000 * (10**uint256(decimals()));

    modifier onlyMintingContract() {
        require(
            msg.sender == mintingContract || msg.sender == owner(),
            "Sorry you dont have persmissions"
        );
        _;
    }

    constructor() ERC20("Ectoplasm", "ECTO") {
        _mint(address(this), 500000000 * (10**uint256(decimals())));
        _approve(address(this), msg.sender, totalSupply());
        _transfer(address(this), msg.sender, totalSupply());
        minted = minted.add(500000000 * (10**uint256(decimals())));
    }

    function setMintingContract(address _contractAddress) public onlyOwner {
        mintingContract = _contractAddress;
    }

    function mint(address _to, uint256 _amount) external onlyMintingContract {
        require(_amount > 0);
        require((minted + _amount) <= hardCap);
        _mint(_to, _amount);
        minted = minted.add(_amount);
    }

    function burn(address user, uint256 amount) external {
        require(amount > 0);
        _burn(user, amount);
    }
}