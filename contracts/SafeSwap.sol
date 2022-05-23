// SPDX-License-Identifier: MIT

pragma solidity =0.6.6;

import '@uniswap/v2-periphery/contracts/UniswapV2Router02.sol';

contract SafeSwap{
    
    string public name = "Swap";
    address internal constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address internal constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    IUniswapV2Router02 public uniswapRouter;
    address payable immutable private owner;

    // Address representating ETH
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor() public payable{
        owner = payable(msg.sender);
        uniswapRouter = IUniswapV2Router02(UNISWAP_V2_ROUTER);
    } 

    receive() external payable{}

    modifier OnlyOwner(){
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function SwapETHForToken(address token, address to) external payable{
        uint deadline = block.timestamp + 150;
        address[] memory path = getETHForTokenPath(token);
        uint amountOutMin = uniswapRouter.getAmountsOut(msg.value, path)[1];
        uniswapRouter.swapExactETHForTokens{value: msg.value}(amountOutMin, path, to, deadline);
    }

    function SwapTokenForETH(uint tokenAmount, address token, address to) external{
        uint deadline = block.timestamp + 150;
        address[] memory path = getTokenForETHPath(token);
        uint amountOutMin = uniswapRouter.getAmountsOut(tokenAmount, path)[1];
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), tokenAmount);
        TransferHelper.safeApprove(token, UNISWAP_V2_ROUTER, tokenAmount);
        uniswapRouter.swapExactTokensForETH(tokenAmount, amountOutMin, path, to, deadline);
    }

    function SwapTokenForToken( 
        address tokenIn,
        address tokenOut,
        uint amountIn,
        address to
        ) external {
            TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
            TransferHelper.safeApprove(tokenIn, UNISWAP_V2_ROUTER, amountIn);

            address[] memory path;
            if (tokenIn == WETH || tokenOut == WETH) {
            path = new address[](2);
            path[0] = tokenIn;
            path[1] = tokenOut;
            } else {
            path = new address[](3);
            path[0] = tokenIn;
            path[1] = WETH;
            path[2] = tokenOut;
            }

            uint amountOutMin = getAmountOutMin(tokenIn, tokenOut, amountIn);
            uint deadline = block.timestamp + 150;
            uniswapRouter.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
            );
    }

    function getETHForTokenPath(address token) private pure returns(address[] memory){
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = token;

        return path;
    }

    function getTokenForETHPath(address token) private pure returns(address[] memory){
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = WETH;

        return path;
    }

    function getAmountOutMin(
        address tokenIn,
        address tokenOut,
        uint amountIn
        ) private view returns (uint) {
            address[] memory path;
            if (tokenIn == WETH || tokenOut == WETH) {
            path = new address[](2);
            path[0] = tokenIn;
            path[1] = tokenOut;
            } else {
            path = new address[](3);
            path[0] = tokenIn;
            path[1] = WETH;
            path[2] = tokenOut;
            }

            // same length as path
            uint[] memory amountOutMins = uniswapRouter.getAmountsOut(amountIn, path);

            return amountOutMins[path.length - 1];
    }

    // Allows to withdraw accidentally sent ETH or tokens.
    function withdraw(
        address token,
        uint amount
        ) external OnlyOwner returns(bool) {
            if(token == ETH) {
            TransferHelper.safeTransferETH(owner, amount);
            } else {
            TransferHelper.safeTransfer(token, owner, amount);
            }
            return true;
    }
}