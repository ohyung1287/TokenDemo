pragma solidity ^0.4.25;
import './ERC721BasicToken.sol';
import './Ownable.sol';


contract DRMToken is ERC721BasicToken, Ownable{
     string public tokenName = "Digital Right Token";
    string public symbol = "DRM";
    struct Artwork{
        string _artworkId;
        string name;
        string artist;
        string description;
        string realart;// link of image 
        string thumbnail;// url image
        uint64 timestamp;
    }
    uint _artworkId = 0;
    Artwork[] public artworks; 
    mapping(uint256 => bool) internal isCreated;
    mapping(address => bool) public registeredArtists;
    mapping(uint256 => uint256) public tokenPrices;
    // mapping(string => uint256[]) public IPFStoID; // filter out a list of ID with same image 
    uint public tokenCount;

    function artistRegister(address _artist, string _name)external onlyOwner{ 
        registeredArtists[_artist] = true;
    }
    function isRegisteredArtist()external returns(bool){
        address sender= msg.sender;
        return registeredArtists[sender];
    }
    function getTokenName()external returns(string){
        return tokenName;
    }
    // Creates artwork as private token
    // 1. Put attributes in new token
    // 2. Transfer token to the artist
    // the new token will belong to artist directly
    function privateCreation(string _name, string _artist, string _description, string _realart, string _thumbnail, uint _deployNum) public { // When artist upload a new artwork to platform
        require(_deployNum > 0);
        require(registeredArtists[msg.sender]);
        for(uint i=0; i < _deployNum ; i++){
            Artwork memory _artwork = Artwork({
                name:_name,
                artist:_artist,
                description:_description,
                realart:_realart,
                thumbnail:_thumbnail,
                timestamp:uint64(now)
            });
            uint256 id = artworks.push(_artwork) - 1;
            _mint(msg.sender, id);
            isCreated[id] = true;
        }
    }
    function publicCreation(uint _price,string _name, string _artist, string _description, string _realart, string _thumbnail, uint _deployNum) public { // When artist upload a new artwork to platform
        require(_deployNum > 0);
        require(registeredArtists[msg.sender]);
        for(uint i=0; i < _deployNum ; i++){
            Artwork memory _artwork = Artwork({
                name:_name,
                artist:_artist,
                description:_description,
                realart:_realart,
                thumbnail:_thumbnail,
                timestamp:uint64(now)
            });
            uint256 id = artworks.push(_artwork) - 1;
            tokenPrices[id] = _price * 1000000000000000000;
            isCreated[id] = true;
        }
    }
    function publicCreationWithContributor(uint _price, address[] _contribuctors, uint[] _percentages,string _name, string _artist, string _description, string _realart, string _thumbnail, uint _deployNum) public { // When artist upload a new artwork to platform
        require(_deployNum > 0);
        require(registeredArtists[msg.sender]);
        for(uint i=0; i < _deployNum ; i++){
            Artwork memory _artwork = Artwork({
                name:_name,
                artist:_artist,
                description:_description,
                realart:_realart,
                thumbnail:_thumbnail,
                timestamp:uint64(now)
            });
            uint256 id = artworks.push(_artwork) - 1;
            tokenPrices[id] = _price * 1000000000000000000;
            isCreated[id] = true;
        }
    }
    function requestBuy(uint256 _tokenId) payable external ifNotPaused {
        require(msg.value >= tokenPrices[_tokenId]);
        require(isCreated[_tokenId]);
        // require(TokenMint(msg.sender,_tokenId));
        _mint(msg.sender, _tokenId); //Mints the token ID of the newest placeholder structure to that wallet address.
        tokenCount++; //adds one to total token count
    }

    modifier TokenMint(address _wallet, uint256 _tokenId){
        _mint(_wallet, _tokenId); //Mints the token ID of the newest placeholder structure to that wallet address.
        tokenCount++; //adds one to total token count
        _;
    }

}