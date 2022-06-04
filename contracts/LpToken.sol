pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LpToken is ERC20, Ownable {

    constructor() ERC20("LpToken", "LPT") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}