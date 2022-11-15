// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Developed by @CryptoMikel

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function burn(address user, uint256 amount) external;
}

library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}

pragma solidity ^0.8.0;

interface IResearchLab {
    function safeLockedTransfer(
        address _to,
        uint256 _pid,
        uint256 _amount
    ) external;

    function getUserInfo(uint256 _pid, address _address)
        external
        view
        returns (
            IERC20 lpToken,
            uint256 amount,
            uint256 bridgedAmount,
            uint256 depositTime,
            uint256 depositBlock,
            uint256 pendingUnlocked,
            uint256 pendingLocked,
            uint256 lockedAmount,
            uint256 vestedAmount,
            uint256 lastRewardBlock
        );
}

contract LabBunnies is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for uint256;

    struct Minter {
        uint256 timeLastMint;
        uint256 twoWeekMints;
        uint16 totalMints;
    }

    struct Attributes {
        uint16 types;
        uint16 eyes;
        uint16 mouth;
        uint16 head;
        string image;
    }

    struct Bunny {
        Attributes attributes;
        uint8 generation;
        uint256 claimsLeft;
        uint8 totalClaims;
        uint8 totalBreeds;
        uint256 timeLastClaim;
        uint256 timeLastBreed;
        bool onClaimCoolDown;
        bool onBreedCoolDown;
    }

    string[] private types = [
        "White Fur",
        "Black Fur",
        "Bloody",
        "Ghost",
        "Zombie"
    ];
    string[] private eyes = [
        "Regular",
        "Angry",
        "Bloodshot",
        "Cat Eyes",
        "Eye Sockets"
    ];
    string[] private mouths = [
        "Regular",
        "Foaming",
        "Bloody",
        "Vampire Teeth",
        "Jawless"
    ];
    string[] private heads = [
        "Regular",
        "Witch Hat",
        "Knife",
        "Nails",
        "Exposed Brain"
    ];
    uint8[] private claimsPerGen = [30, 25, 20, 15];
    uint8[] private breedsPerGen = [3, 2, 1, 0];
    uint16[] private mintingOdds = [400, 300, 175, 90, 35];
    uint16[] private headsOdds = [800, 85, 65, 40, 10];
    uint256[] private claimingPower = [25, 35, 60, 100, 250];

    IResearchLab public researchLab;
    IERC20 public erc20;

    mapping(uint256 => Bunny) bunnies;
    mapping(address => Minter) public minters;
    mapping(address => bool) claimBlacklist;
    mapping(uint256 => bool) transferBlacklist;

    string public CID;
    bool public isPaused = true;
    bool public isBurn = true;
    bool public isBreedingPaused = true;
    uint256 private claimsPerCarrotPercent;
    uint256 private claimCooldown = 1 days;
    uint256 private maxPerMintCooldown = 3;
    uint256 private mintCooldown = 2 weeks;
    uint256 public maxSupply = 10000;
    uint256 public price = 24000 * 10**18;
    uint256 public rechargePrice = 24000 * 10**18;
    uint256 public breedingPrice = 26500 * 10**18;
    uint256 public maximumClaimablePercentage = 10;
    uint256 tokenId = 1;

    constructor(
        address _ecto,
        address _researchLab,
        uint256 _claimsPerCarrotPercent,
        string memory _CID
    ) ERC721("Lab Bunnies", "LB") {
        erc20 = IERC20(_ecto);
        researchLab = IResearchLab(_researchLab);
        claimsPerCarrotPercent = _claimsPerCarrotPercent;
        CID = _CID;
    }

    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 _tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        require(
            transferBlacklist[_tokenId] == false,
            "It seems that you are a bad boy, you are blacklisted!"
        );
        // Check if still in cooldown, if not it deactivates it
        if (
            block.timestamp.sub(bunnies[_tokenId].timeLastClaim) >=
            claimCooldown
        ) {
            bunnies[_tokenId].onClaimCoolDown = false;
        }
        // Check if in cooldown
        require(
            bunnies[_tokenId].onClaimCoolDown == false,
            "You cannot claim in the next 24h after claiming"
        );
        super._beforeTokenTransfer(from, to, _tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setClaimsPerCarrotPercent(uint256 _amount) public onlyOwner {
        claimsPerCarrotPercent = _amount;
    }

    function updateErc20(address _ecto) public onlyOwner {
        erc20 = IERC20(_ecto);
    }

    function updateLab(address _lab) public onlyOwner {
        researchLab = IResearchLab(_lab);
    }

    function updateClaimingPower(uint256[] memory _claimingPower)
        public
        onlyOwner
    {
        claimingPower = _claimingPower;
    }

    function setMaximumClaimablePercentage(uint256 _maxPercentage)
        public
        onlyOwner
    {
        maximumClaimablePercentage = _maxPercentage;
    }

    function setGen1Claims(uint8 _claims) public onlyOwner {
        claimsPerGen[0] = _claims;
    }

    function setGen2Claims(uint8 _claims) public onlyOwner {
        claimsPerGen[1] = _claims;
    }

    function setGen3Claims(uint8 _claims) public onlyOwner {
        claimsPerGen[2] = _claims;
    }

    function setGen4Claims(uint8 _claims) public onlyOwner {
        claimsPerGen[3] = _claims;
    }

    function setClaimCooldown(uint8 _cooldown) public onlyOwner {
        claimCooldown = _cooldown;
    }

    function setMaxPerMintCooldown(uint8 _max) public onlyOwner {
        maxPerMintCooldown = _max;
    }

    function setMintCooldown(uint256 _cooldown) public onlyOwner {
        mintCooldown = _cooldown;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setCID(string memory _newCid) public onlyOwner {
        CID = _newCid;
    }

    function setBreedingPrice(uint256 _newPrice) public onlyOwner {
        breedingPrice = _newPrice;
    }

    function setRechargePrice(uint256 _newPrice) public onlyOwner {
        rechargePrice = _newPrice;
    }

    function setMaxSupply(uint256 _quantity) public onlyOwner {
        maxSupply = _quantity;
    }

    function flipPauseStatus() public onlyOwner {
        isPaused = !isPaused;
    }

    function flipBreedingPauseStatus() public onlyOwner {
        isBreedingPaused = !isBreedingPaused;
    }

    function toggleBurn() public onlyOwner {
        isBurn = !isBurn;
    }

    function getPrice(uint256 _quantity) public view returns (uint256) {
        return _quantity * price;
    }

    // this was used to create the distributon of 10,000 and tested for uniqueness for the given parameters of this collection
    function random(
        address sender,
        string memory _tokenId,
        string memory _attr
    ) private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        sender,
                        _tokenId,
                        _attr
                    )
                )
            );
    }

    function usew(uint16[] memory w, uint256 i) internal pure returns (uint16) {
        uint16 ind = 0;
        uint256 j = uint256(w[0]);
        while (j <= i) {
            ind++;
            j += uint256(w[ind]);
        }
        return ind;
    }

    function randomOne(uint256 _tokenId, address sender)
        internal
        view
        returns (Attributes memory)
    {
        Attributes memory randomAttr;
        string memory __types = string(
            abi.encodePacked(types[0], types[1], types[2], types[3], types[4])
        );
        string memory __eyes = string(
            abi.encodePacked(eyes[0], eyes[1], eyes[2], eyes[3], eyes[4])
        );
        string memory __mouths = string(
            abi.encodePacked(
                mouths[0],
                mouths[1],
                mouths[2],
                mouths[3],
                mouths[4]
            )
        );
        string memory __heads = string(
            abi.encodePacked(heads[0], heads[1], heads[2], heads[3], heads[4])
        );
        randomAttr.types = usew(
            mintingOdds,
            random(sender, _tokenId.toString(), __types) % 1000
        );
        randomAttr.eyes = usew(
            mintingOdds,
            random(sender, _tokenId.toString(), __eyes) % 1000
        );
        randomAttr.mouth = usew(
            mintingOdds,
            random(sender, _tokenId.toString(), __mouths) % 1000
        );
        randomAttr.head = usew(
            headsOdds,
            random(sender, _tokenId.toString(), __heads) % 1000
        );
        return randomAttr;
    }

    function mint(uint256 _quantity) public {
        require(isPaused == false, "Sale is not active at the moment");
        require(
            totalSupply() < maxSupply,
            "Quantity is greater than remaining Supply"
        );
        require(
            price.mul(_quantity) <= erc20.balanceOf(msg.sender),
            "Sent ether value is incorrect"
        );

        // Checks if the address has minted the maximum amount
        if (minters[msg.sender].twoWeekMints >= maxPerMintCooldown) {
            // If true, then it checks if has passed at least 2 weeks since then
            if (
                block.timestamp.sub(minters[msg.sender].timeLastMint) >=
                mintCooldown
            ) {
                // If true, then it resets the twoWeekMints to 0
                minters[msg.sender].twoWeekMints = 0;
            }
        }

        // Mints must be less than the maximum
        require(
            minters[msg.sender].twoWeekMints < maxPerMintCooldown,
            "3 mints in a week"
        );

        // Calculate mints left until cooldown of 2 weeks
        uint256 mintsLeft = maxPerMintCooldown.sub(
            minters[msg.sender].twoWeekMints
        );

        // Quantity minted in this tx must be less or equal to the mints left
        require(_quantity <= mintsLeft, "Quantity exceeds mint limit");
        if (isBurn == false) {
            erc20.transferFrom(msg.sender, address(this), price.mul(_quantity));
        } else erc20.burn(msg.sender, price.mul(_quantity));

        for (uint256 i = 0; i < _quantity; i++) {
            _safeMint(msg.sender, totalsupply());
            bunnies[totalSupply()].generation = 0;
            bunnies[totalSupply()].claimsLeft = claimsPerGen[0];
            bunnies[totalSupply()].attributes = randomOne(
                totalSupply(),
                msg.sender
            );
            bunnies[totalSupply()].attributes.image = generateImageName(totalSupply());
            tokenId++;
            // We update the last mint time as well as the total mints and twoWeekMints
            minters[msg.sender].totalMints++;
            minters[msg.sender].twoWeekMints++;
            minters[msg.sender].timeLastMint = block.timestamp;
        }
    }

    function airdrop(address user, uint256 _quantity) public onlyOwner {
        require(isPaused == false, "Sale is not active at the moment");

        require(
            totalSupply().add(_quantity) < maxSupply,
            "Quantity is greater than remaining Supply"
        );

        for (uint256 i = 0; i < _quantity; i++) {
            _safeMint(user, totalsupply());
            bunnies[totalSupply()].generation = 0;
            bunnies[totalSupply()].claimsLeft = claimsPerGen[0];
            bunnies[totalSupply()].attributes = randomOne(totalSupply(), user);
            bunnies[totalSupply()].attributes.image = generateImageName(totalSupply());
            tokenId++;
        }
    }

    function breeding(uint256 _tokenid1, uint256 _tokenid2) public {
        require(
            ownerOf(_tokenid1) == msg.sender && ownerOf(_tokenid2) == msg.sender
        );
        require(bunnies[_tokenid1].generation != 3, "Gen4 cannot breed");
        if (
            block.timestamp.sub(bunnies[_tokenid1].timeLastBreed) >=
            claimCooldown
        ) {
            bunnies[_tokenid1].onBreedCoolDown = false;
        }
        if (
            block.timestamp.sub(bunnies[_tokenid2].timeLastBreed) >=
            claimCooldown
        ) {
            bunnies[_tokenid2].onBreedCoolDown = false;
        }
        require(
            bunnies[_tokenid1].onBreedCoolDown == false &&
                bunnies[_tokenid2].onBreedCoolDown == false,
            "On cooldown"
        );
        require(
            bunnies[_tokenid1].totalBreeds <
                breedsPerGen[bunnies[_tokenid1].generation],
            "Exceeds total breeds"
        );
        require(
            bunnies[_tokenid2].totalBreeds <
                breedsPerGen[bunnies[_tokenid2].generation],
            "Exceeds total breeds"
        );
        require(isBreedingPaused == false, "Sale is not active at the moment");
        require(
            totalSupply() < maxSupply,
            "Quantity is greater than remaining Supply"
        );
        require(
            breedingPrice <= erc20.balanceOf(msg.sender),
            "Sent ether value is incorrect"
        );

        if (isBurn == false) {
            erc20.transferFrom(msg.sender, address(this), breedingPrice);
        } else IERC20(erc20).burn(msg.sender, breedingPrice);

        _safeMint(msg.sender, totalsupply());
        bunnies[_tokenid1].totalBreeds++;
        bunnies[_tokenid2].totalBreeds++;
        bunnies[_tokenid1].timeLastBreed = block.timestamp;
        bunnies[_tokenid2].timeLastBreed = block.timestamp;
        bunnies[_tokenid1].onBreedCoolDown = true;
        bunnies[_tokenid2].onBreedCoolDown = true;
        if (bunnies[_tokenid1].generation > bunnies[_tokenid2].generation) {
            bunnies[totalSupply()].generation =
                bunnies[_tokenid1].generation +
                1;
        } else if (
            bunnies[_tokenid2].generation > bunnies[_tokenid1].generation
        ) {
            bunnies[totalSupply()].generation =
                bunnies[_tokenid2].generation +
                1;
        } else {
            bunnies[totalSupply()].generation =
                bunnies[_tokenid1].generation +
                1;
        }
        bunnies[totalSupply()].claimsLeft = claimsPerGen[
            bunnies[totalSupply()].generation
        ];
        bunnies[totalSupply()].attributes = randomOne(
            totalSupply(),
            msg.sender
        );
        bunnies[totalSupply()].attributes.image = generateImageName(totalSupply());
        tokenId++;
    }

    function claim(uint256 _poolId, uint256 bunnyId) public nonReentrant {
        // Check if in blacklist
        require(
            claimBlacklist[msg.sender] == false,
            "Bad boys are not allowed to claim"
        );
        // Check if still in cooldown, if not it deactivates it
        if (
            block.timestamp.sub(bunnies[bunnyId].timeLastClaim) >= claimCooldown
        ) {
            bunnies[bunnyId].onClaimCoolDown = false;
        }
        // Check if in cooldown
        require(
            bunnies[bunnyId].onClaimCoolDown == false,
            "You cannot claim in the next 24h after claiming"
        );
        require(
            bunnies[bunnyId].claimsLeft > 0,
            "You cannot claim if you exceed the limit"
        );

        uint256 bunnyClaimingPower = claimingPower[
            bunnies[bunnyId].attributes.types
        ] +
            claimingPower[bunnies[bunnyId].attributes.eyes] +
            claimingPower[bunnies[bunnyId].attributes.mouth] +
            claimingPower[bunnies[bunnyId].attributes.head];
        uint256 lockedRewards;
        uint256 lockedAmount;
        uint256 pendingLocked;
        (, , , , , , pendingLocked, lockedAmount, , ) = researchLab.getUserInfo(
            _poolId,
            msg.sender
        );
        lockedRewards = lockedAmount.add(pendingLocked);
        uint256 claimableAmount = lockedRewards
            .mul(maximumClaimablePercentage)
            .div(1000);
        uint256 claimedRewards = claimableAmount.mul(bunnyClaimingPower).div(
            1000
        );
        // Claims the reward :)
        researchLab.safeLockedTransfer(msg.sender, _poolId, claimedRewards);

        // Sets cooldown
        bunnies[bunnyId].onClaimCoolDown = true;
        // Increases total claims
        bunnies[bunnyId].totalClaims++;
        // Increases claims since it was recharged
        bunnies[bunnyId].claimsLeft--;
        // Sets latest claim date
        bunnies[bunnyId].timeLastClaim = block.timestamp;
    }

    function recharge(uint256 _amount, uint256 bunnyId) public {
        // Check if in blacklist
        require(
            claimBlacklist[msg.sender] == false,
            "Bad boys are not allowed to claim"
        );

        require(
            erc20.balanceOf(msg.sender) >= rechargePrice.mul(_amount),
            "You must enough tokens to burn"
        );

        require(
            bunnies[bunnyId].claimsLeft <=
                claimsPerGen[bunnies[bunnyId].generation],
            "You must have claims left to recharge"
        );

        //In order to burn the tokens, the erc20 token must be burnable. Please ensure it is, by the moment it just transfers it to this contract.
        if (isBurn == false) {
            erc20.transferFrom(
                msg.sender,
                address(this),
                rechargePrice.mul(_amount)
            );
        } else IERC20(erc20).burn(msg.sender, rechargePrice.mul(_amount));

        // Adds claims per carrot
        for (uint256 i = 0; i < _amount; i++) {
            bunnies[bunnyId].claimsLeft += claimsPerCarrotPercent
                .mul(claimsPerGen[bunnies[bunnyId].generation])
                .div(1000);
        }

        if (
            bunnies[bunnyId].claimsLeft >
            claimsPerGen[bunnies[bunnyId].generation]
        ) {
            bunnies[bunnyId].claimsLeft = claimsPerGen[
                bunnies[bunnyId].generation
            ];
        }
    }

    function addToBlacklist(address _badBoy) public onlyOwner {
        claimBlacklist[_badBoy] = true;
    }

    function removeFromBlacklist(address _badBoy) public onlyOwner {
        claimBlacklist[_badBoy] = false;
    }

    function addGroupToBlacklist(address[] memory _badBoys) public onlyOwner {
        for (uint256 i; i < _badBoys.length; i++) {
            claimBlacklist[_badBoys[i]] = true;
        }
    }

    function removeGroupFromBlacklist(address[] memory _badBoys)
        public
        onlyOwner
    {
        for (uint256 i; i < _badBoys.length; i++) {
            claimBlacklist[_badBoys[i]] = false;
        }
    }

    function addToTransferBlacklist(uint256 _badBoy) public onlyOwner {
        transferBlacklist[_badBoy] = true;
    }

    function removeFromTransferBlacklist(uint256 _badBoy) public onlyOwner {
        transferBlacklist[_badBoy] = false;
    }

    function addGroupToTransferBlacklist(uint256[] memory _badBoys)
        public
        onlyOwner
    {
        for (uint256 i; i < _badBoys.length; i++) {
            transferBlacklist[_badBoys[i]] = true;
        }
    }

    function removeGroupFromTransferBlacklist(uint256[] memory _badBoys)
        public
        onlyOwner
    {
        for (uint256 i; i < _badBoys.length; i++) {
            transferBlacklist[_badBoys[i]] = false;
        }
    }

    function tokensOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(_owner);
        uint256[] memory result = new uint256[](count);
        for (uint256 index = 0; index < count; index++) {
            result[index] = tokenOfOwnerByIndex(_owner, index);
        }
        return result;
    }

    function setTokenImage(string memory image, uint256 _tokenId)
        external
        onlyOwner
    {
        bunnies[_tokenId].attributes.image = image;
        //console.log("Changing image from '%s' to '%s'", bunnies[_tokenId].attributes.image);
    }

    function generateImageName(uint256 _tokenId) internal view returns (string memory){
        string memory tokenType = types[bunnies[_tokenId].attributes.types];
        if(compareStrings(tokenType, "White Fur")){
            tokenType = "WhiteFur";
        }else if(compareStrings(tokenType, "Black Fur")){
            tokenType = "BlackFur";
        }
        string memory tokenHead = heads[bunnies[_tokenId].attributes.head];
        if(compareStrings(tokenHead, "Witch Hat")){
            tokenHead = "WitchHat";
        }else if(compareStrings(tokenHead, "Exposed Brain")){
            tokenHead = "ExposedBrain";
        }
        string memory tokenEyes = eyes[bunnies[_tokenId].attributes.eyes];
        if(compareStrings(tokenEyes, "Cat Eyes")){
            tokenEyes = "CatEyes";
        }else if(compareStrings(tokenEyes, "Eye Sockets")){
            tokenEyes = "EyeSockets";
        }
        string memory tokenMouth = mouths[bunnies[_tokenId].attributes.mouth];
        if(compareStrings(tokenMouth, "Vampire Teeth")){
            tokenMouth = "VampireTeeth";
        }
        return string(
                abi.encodePacked(
                    'ipfs://',
                    CID,
                    '/',
                    tokenType,
                    '_',
                    tokenHead,
                    '_',
                    tokenEyes,
                    '_',
                    tokenMouth,
                    '.png'
                    )
                );
    }

    function getTokenImage(uint256 _tokenId)
        external
        view
        returns (string memory)
    {
        return bunnies[_tokenId].attributes.image;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Lab Bunny #',
                                    _tokenId.toString(),
                                    '", "attributes": [{"trait_type":"Type", "value":"',
                                    types[bunnies[_tokenId].attributes.types],
                                    '"},{"trait_type":"Eyes", "value":"',
                                    eyes[bunnies[_tokenId].attributes.eyes],
                                    '"},{"trait_type":"Mouth", "value":"',
                                    mouths[bunnies[_tokenId].attributes.mouth],
                                    '"},{"trait_type":"Head", "value":"',
                                    heads[bunnies[_tokenId].attributes.head],
                                    '"}],',
                                    '"image":"',
                                    bunnies[_tokenId].attributes.image,
                                    '"}'
                                )
                            )
                        )
                    )
                )
            );
    }

    function totalsupply() private view returns (uint256) {
        return tokenId;
    }
}
