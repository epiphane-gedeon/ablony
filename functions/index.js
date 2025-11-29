const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/v2/https");
const fetch = require("node-fetch");

setGlobalOptions({maxInstances: 10});

exports.verifyRecaptcha = onRequest(async (req, res) => {
  const token = req.body.token;
  const secret = require("firebase-functions").config().recaptcha.secret;

  if (!token) {
    return res.status(400).json({success: false, message: "Token manquant"});
  }

  try {
    const response = await fetch(
        `https://www.google.com/recaptcha/api/siteverify?secret=${secret}&response=${token}`,
        {method: "POST"},
    );
    const data = await response.json();
    if (data.success) {
      res.json({success: true});
    } else {
      res.json({success: false, errorCodes: data["error-codes"]});
    }
  } catch (error) {
    res.status(500).json({success: false, message: "Erreur serveur"});
  }
});
