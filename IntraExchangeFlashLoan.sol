// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import { FlashLoanReceiverBase } from "./FlashLoanReceiverBase.sol";
import { ILendingPool, ILendingPoolAddressesProvider, IERC20 } from "./Interfaces.sol";
import { SafeMath } from "./Libraries.sol";
import "https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";


contract MyV2FlashLoan is FlashLoanReceiverBase {
    using SafeMath for uint256;
    IUniswapV2Router02 public immutable uniRouter;
    IUniswapV2Router02 public immutable sushiRouter;
    IUniswapV2Router02 public immutable shibaRouter;
    address public ownerOfContract;

    constructor(ILendingPoolAddressesProvider _addressProvider, address _uniRouter, address _sushiRouter, address _shibaRouter) FlashLoanReceiverBase(_addressProvider) public {
        uniRouter = IUniswapV2Router02(_uniRouter);
        sushiRouter = IUniswapV2Router02(_sushiRouter);
        shibaRouter = IUniswapV2Router02(_shibaRouter);
        ownerOfContract = msg.sender;
    }

    modifier solamenteOwner {
        require(msg.sender == ownerOfContract, "Must be owner of contract to call this function brah");
        _;
    }

    function withdrawToken(address _tokenContract) public solamenteOwner() {
        uint assetBalance;
        IERC20 tokenContract = IERC20(_tokenContract);
        assetBalance = tokenContract.balanceOf(address(this));
        tokenContract.transfer(msg.sender, assetBalance);
    }

    function ERC20BalanceContract(address token0Address) external view returns (uint256) {
        IERC20 token0Contract = IERC20(token0Address);
        return token0Contract.balanceOf(address(this));
    }

    function ERC20BalanceWallet(address token0Address) external view returns (uint256) {
        IERC20 token0Contract = IERC20(token0Address);
        return token0Contract.balanceOf(msg.sender);
    }

    function approveERC20Token(address tokenAddress, address exchangeRouterAddress, uint256 amountIn) public {
        IERC20(tokenAddress).approve(address(exchangeRouterAddress), amountIn);
    }


    // SpookySwap swap function
    function swapOnUniSwap(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path
    ) internal {
        require(
            IERC20(_path[0]).approve(address(uniRouter), _amountIn),
            "UniSwap approval failed."
        );

        uniRouter.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            _path,
            address(this),
            (block.timestamp + 1200)
        );
    }

    // SushiSwap swap function
    function swapOnSushiSwap(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path
    ) internal {
        require(
            IERC20(_path[0]).approve(address(sushiRouter), _amountIn),
            "SushiSwap approval failed."
        );

        sushiRouter.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            _path,
            address(this),
            (block.timestamp + 1200)
        );
    }

    // SpiritSwap function
    function swapOnShibaSwap(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path
    ) internal {
        require(
            IERC20(_path[0]).approve(address(shibaRouter), _amountIn),
            "ShibaSwap approval failed."
        );

        shibaRouter.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            _path,
            address(this),
            (block.timestamp + 1200)
        );
    }


    function myFlashLoanCall(string memory _dex, address _token0AddressFLASHTOKEN, address[] memory _pathArray, uint256 _flashAmount) solamenteOwner() public {
        address receiverAddress = address(this);

        address[] memory assets = new address[](1);
        assets[0] = _token0AddressFLASHTOKEN;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _flashAmount;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            modes[i] = 0;
        }

        address onBehalfOf = address(this);

        //params (extra data)
        bytes memory params = abi.encode(
            _dex,
            _token0AddressFLASHTOKEN,
            _pathArray,
            _flashAmount
        );

        uint16 referralCode = 0;

        LENDING_POOL.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    )
        external
        override
        returns (bool)
    {
        // Decode paramaters
        {
        (
            string memory dex,
            address token0Address,
            address[] memory pathArray,
            uint256 flashAmount
        ) = abi.decode(params, (string, address, address[], uint256));

        // Execute Arbitrage logic here
        // uint256 balanceToken0Before = IERC20(token0Address).balanceOf(address(this));  // Balance of my wallet of token0 before swap

        // Swap logic here
        if (keccak256(abi.encodePacked(dex)) == keccak256(abi.encodePacked("uniswap"))) {
            swapOnUniSwap(flashAmount, 0, pathArray);
        } else if (keccak256(abi.encodePacked(dex)) == keccak256(abi.encodePacked("sushiswap"))) {
            swapOnSushiSwap(flashAmount, 0, pathArray);
        } else if (keccak256(abi.encodePacked(dex)) == keccak256(abi.encodePacked("shibaswap"))) {
            swapOnShibaSwap(flashAmount, 0, pathArray);
        } else {
            revert("Invalid dex brah");
        }

        // uint256 balanceToken0After = IERC20(token0Address).balanceOf(address(this));
        // require(balanceToken0After > balanceToken0Before, "Swap was not profitable, transaction reverted");

        // Transfer money from contract to my wallet
        // uint256 amountToReturnToFlashloanContract = amounts[0].add(premiums[0]);
        uint256 flashLoanFee = premiums[0];
        uint256 amountToReturnToFlashloanContract = flashAmount + flashLoanFee;
        uint256 amountToTransferBackToWallet = (IERC20(token0Address).balanceOf(address(this)) - amountToReturnToFlashloanContract);


        IERC20 token0Contract = IERC20(token0Address);
        token0Contract.transfer(ownerOfContract, amountToTransferBackToWallet);
        }

        // Push money back
        for (uint i = 0; i < assets.length; i++) {
            uint amountOwing = amounts[i].add(premiums[i]);
            IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
        }
        
        return true;
    }
}
