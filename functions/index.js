/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({maxInstances: 10});

exports.ocrExtract = onRequest(async (request, response) => {
  try {
    if (request.method !== "POST") {
      response.status(405).json({error: "Method not allowed"});
      return;
    }

    const imageBase64 = request.body && request.body.image_base64;
    if (!imageBase64) {
      response.status(400).json({error: "image_base64 is required"});
      return;
    }

    // Placeholder response so deployment and URL setup can complete.
    // Next step: replace this with real OCR provider call.
    response.status(200).json({
      text: "",
      data: {
        name: "",
        company: "",
        phone: "",
        email: "",
        website: "",
        address: "",
        businessType: "Other",
      },
    });
  } catch (error) {
    response.status(500).json({error: String(error)});
  }
});
