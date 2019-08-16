pragma solidity ^0.5.0;
import 'zeppelin-solidity/contracts/token/ERC721/ERC721Token.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';


contract DAMToken is ERC721BasicToken, Ownable{
    string public tokeName = "Digital Right Token";
    string public symbol = "DRM";

    struct Artwork{
        string name;
        string artist;
        string description;
        string IPFS;// link of image 
    }
    uint _artworkId = 0;
    mapping(uint256 => Artwork) public artworks; 
    mapping(uint256 => uint256) public tokenPrices;
    uint public tokenCount;
    function setTokenPrice(uint _tokenId, uint _price) public onlyOwner{
        require(exists(_tokenId));
        tokenPrices[_tokenId] = _price;
    }
    function ArtworkCreation(string _name, string _artist, string _description, string _IPFS) public { // When artist upload a new artwork to platform
        artworks[_artworkId++] = Artwork(_name, _artist, _description, _IPFS); //creates a place holder structure for clients future marble

    }
    function requestBuy(uint256 _tokenId) payable external ifNotPaused priceCheck(_tokenId) {
        deposit(msg.value);
    }
    modifier TokenMint(address _wallet, uint256 _tokenId){
        _mint(_wallet, _tokenId); //Mints the token ID of the newest placeholder structure to that wallet address.
        tokenCount++; //adds one to total token count
        _;
    }
}