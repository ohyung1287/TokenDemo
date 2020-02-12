const express = require("express");
const app = express();
const cors = require("cors");
const Web3 = require("web3");
const abi = require("./abi");
const fetch = require("node-fetch");
const Tx = require("ethereumjs-tx");
const BigNumber = require("bignumber.js");
const bodyParser = require("body-parser");
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

//envSetup
let web3;
let DRM_address = "0x019d07b1227910088bd823402775779900e1adbb";
let DRM_owner = "0x5efDD3CAb3c3Ea3D1725B8EaF340Cc8d5a9B7547";
let DRM_ownerKey =
  "45F93E7A6CF774228519708AA97529A9CE2A663E26E67F183FE49BB9C90D468D";

var infuraLink =
  "https://rinkeby.infura.io/v3/7a19de34892e4625b8464eac960146b7";
web3 = new Web3(new Web3.providers.HttpProvider(infuraLink));
let DRM = new web3.eth.Contract(abi, DRM_address);
app.get("/getTokenName/", async (req, res) => {
  var name = await DRM.methods.owner().call();
  res.send(name);
});
app.post("/getOwnerTokens/", async (req, res) => {
  var address = req.body.address;
  var tokenList = await DRM.methods.tokensOwned(address).call();
  var resJson = [];
  if (tokenList.length) {
    for (var i = 0; i < tokenList.length; i++) {
      var artwork = await DRM.methods.artworks(tokenList[i]).call();
      artwork.id = tokenList[i];
      resJson.push(artwork);
    }
  }

  res.send(resJson);
});
app.get("/getOnStoreTokens/", async (req, res) => {
  var storeList = await DRM.methods.getOnStoreTokens().call();
  var resJson = [];
  if (storeList.length) {
    for (var i = 0; i < storeList.length; i++) {
      var artwork = await DRM.methods.artworks(storeList[i]).call();
      artwork.id = storeList[i];
      resJson.push(artwork);
    }
  }
  res.send(resJson);
});
app.post("/artistRegister/", async (req, res) => {
  try {
    var address = req.body.address;
    console.log(`registering artist ${address}`);

    var transfer = await DRM.methods.artistRegister(address).encodeABI();
    await sendTxn(transfer);
    res.sendStatus(200);
  } catch (err) {
    console.log(err);
    res.send(err);
  }
});
// @param (string[]contributes,int[]percentages,string[]constraints,int priceWei,string name,string artist,string desc,string realart, string thumbnail)
app.post("/tokenGenerate/", async (req, res) => {
  try {
    var contributes = req.body.contributes; // address array -- [addr1, addr2]
    contributes = contributes.split(",");
    var percentages = req.body.percentages; // % array 1-10 -- [5,5]
    percentages = percentages.split(",");
    var constraints = req.body.constraints; // nullable string array -- ["School","Governmant","Bank"]
    var price = req.body.price;
    price = new BigNumber(price * 1000000000000000000);
    var num = req.body.num;
    var name = req.body.title;
    var artist = req.body.artist;
    var description = req.body.description;
    var realart = req.body.realart;
    var thumbnail = req.body.thumbnail; // URL only
    /**
     *  upload File to server, generate an URL
     **/
    var deployNum = req.body.deployNum;
    var metadata = [name, artist, "description", realart, thumbnail];
    console.log(metadata);
    var transfer = await DRM.methods
      .tokenGenerate(
        contributes,
        percentages,
        constraints,
        price.toString(),
        metadata,
        num //deployNum
      )
      .encodeABI();
    await sendTxn(transfer);
    res.sendStatus(200);
  } catch (err) {
    console.log(err);
    res.send(err);
  }
});
async function sendTxn(transfer) {
  var count = await web3.eth.getTransactionCount(DRM_owner);
  rawTransaction = {
    from: DRM_owner,
    nonce: web3.utils.toHex(count),
    gasPrice: 10000000000,
    gasLimit: 2100000,
    to: DRM_address,
    value: "0x0",
    data: transfer,
    chainId: 0x04
  };
  var keyStr = DRM_ownerKey;

  var privKey = Buffer.from(keyStr, "hex");
  var tx = new Tx(rawTransaction);
  tx.sign(privKey);
  var serializedTx = tx.serialize();
  var txn = await web3.eth.sendSignedTransaction(
    "0x" + serializedTx.toString("hex")
  );
  console.log(txn);
}
app.listen(8080, () => console.log("Listening on port 8080..."));
