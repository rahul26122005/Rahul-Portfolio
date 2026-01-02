import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import axios from "axios";

// 🔐 Secure secret (v2 recommended)
const FAST2SMS_KEY = defineSecret("FAST2SMS_KEY");

export const sendAbsentSMS = onCall(
  {secrets: [FAST2SMS_KEY]},
  async (request) => {
    // ✅ AUTH CHECK
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Authentication required"
      );
    }

    // ✅ SAFE DATA ACCESS
    const {mobile, studentName, date} = request.data as {
      mobile: string;
      studentName: string;
      date: string;
    };

    if (!mobile || !studentName || !date) {
      throw new HttpsError(
        "invalid-argument",
        "Missing required fields"
      );
    }

    try {
      const response = await axios.post(
        "https://www.fast2sms.com/dev/bulkV2",
        {
          route: "dlt",
          message: `Dear Parent, your child ${studentName}
           was absent on ${date}.`,
          language: "english",
          numbers: mobile,
        },
        {
          headers: {
            "authorization": FAST2SMS_KEY.value(),
            "Content-Type": "application/json",
          },
        }
      );

      return {
        success: true,
        fast2sms: response.data,
      };
    } catch (error) {
      console.error("SMS Error:", error);
      throw new HttpsError(
        "internal",
        "SMS sending failed"
      );
    }
  }
);
/*
import {onCall} from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

admin.initializeApp();

export const sendAbsentSms = onCall(async (request) => {
  if (!request.auth) {
    throw new Error('Unauthenticated');
  }

  const {mobile, studentName, date} = request.data as {
    mobile: string;
    studentName: string;
    date: string;
  };

  if (!mobile || !studentName || !date) {
    throw new Error('Missing parameters');
  }

  // TODO: Call Fast2SMS API here
  console.log(`SMS -> ${mobile}: ${studentName} absent on ${date}`);

  return {success: true};
});

*/
