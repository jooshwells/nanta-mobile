import bcrypt from "bcryptjs";
import User from "./auth.model.js";
import jwt from "jsonwebtoken";
import nodemailer from "nodemailer";
import ejs from "ejs";
import fs from "fs";
import { normalize_system_error_response } from "../../../custom.middleware.js";

/**
 * @Precondition
 * The request body contains a JSON object with validated registration fields:
 * - first_name
 * - last_name
 * - email
 * - password
 *
 * These fields have already passed validation via `validate_registration_input`.
 *
 * @Condition
 * - Hashes the password using bcrypt with a salt round of 10.
 * - Creates a new User document with the registration field inputs and the hashed password.
 * - Saves the user to the database.
 * - Sends a verification email to the registered email address.
 *
 * @Postcondition
 * - A new user is persisted in the database with a hashed password.
 * - A verification email is sent.
 * - Responds with status `200` and a success message on success.
 * - If an error occurs, the error is passed to the error-handling middleware.
 */
export const register_user = async (req, res, next) => {
  try {
    const { first_name, last_name, email, password } = req.body;
    const hash = await bcrypt.hash(password, 10);
    const user = new User({ first_name, last_name, email, password: hash });
    user.verification_token = jwt.sign(
      {
        type: "email-verification-token",
        user: { _id: user._id, email: user.email },
      },
      process.env.JWT_SECRET,
      { expiresIn: "12h" }
    );
    await user.save();
    req.body.user = user;
    // await send_verification_email(req, res, next); // appears to not be working at the moment
    return res.status(200).send("User registered successfully!");
  } catch (err) {
    next(err);
  }
};

/**
 * @Precondition
 * @Condition
 * @Postcondition
 */
export const login_user = (req, res) => {
  try {
    const { user } = req.body;
    const session_token = jwt.sign(
      { type: "session-token", user: { _id: user._id, email: user.email } },
      process.env.JWT_SECRET,
      { expiresIn: "1h" }
    );
    initialize_session_cookie(req, res, session_token);
    // console.log(res);
    /*Change the return to return JSON that has user info for 
    profile page use, and the token instead of cookies (better for mobile)*/
    return res.status(200).json({
      message: "User logged in successfully!",
      token: session_token,
      user: {
        id: user._id,
        first_name: user.first_name,
        last_name: user.last_name,
        email: user.email,
        is_verified: user.is_verified,
        profile_pic: user.profile_pic,
      },
    });
  } catch (error) {
    return res.status(500).json({
      succes: false,
      message: "Login failed",
      error: error.message,
    });
  }
};

/**
 * @Precondition
 * @Condition
 * @Postcondition
 */
export const logout_user = (req, res) => {
  try {
    res.cookie("nanta-session", "", {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "lax",
      expires: new Date(0),
    });
    return res.status(200).json({
      success: true,
      message: "User logged out successfully!",
    });
  } catch (error) {
    console.error("Logout error:", error);
    return res.status(500).json({
      success: false,
      message: "Error during logout",
    });
  }
};

/**
 * @Precondition
 * @Condition
 * @Postcondition
 */
export const get_user_data = (req, res) => {
  try {
    const user = req.user;
    if (!req.user) {
      console.log("ERROR: No user on request!");
      return res.status(401).json({
        success: false,
        message: "Unauthorized",
      });
    }
    return res.status(200).json({
      success: true,
      data: {
        user: {
          id: user._id,
          first_name: user.first_name,
          last_name: user.last_name,
          email: user.email,
          is_verified: user.is_verified,
          profile_pic: user.profile_pic,
        },
      },
      message: "User retrieved successfully!",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Server error",
    });
  }
};

/**
 * @Precondition
 * @Condition
 * @Postcondition
 */
export const authenticate_user = (req, res) => {
  try {
    return res.status(200).send({ authorization_status: "Authorized" });
  } catch (err) {
    next(err);
  }
};

/**
 * @Precondition
 * @Condition
 * @Postcondition
 */
export const verify_user_email = (req, res) => {
  try {
    const { user } = req.body;

    user.verification_token = null;
    user.is_verified = true;

    return res.status(200).send({ verification_status: "Verified" });
  } catch (error) {}
};

/**
 * @Precondition
 * @Condition
 * @Postcondition
 */
export const send_verification_email = async (req, res, next) => {
  try {
    const { user } = req.body;

    const transporter = nodemailer.createTransport({
      host: process.env.MAIL_HOST,
      port: process.env.MAIL_PORT,
      secure: false,
      auth: {
        user: process.env.MAIL_USER,
        pass: process.env.MAIL_PASS,
      },
    });

    const html_template = fs.readFileSync(
      "./src/modules/auth/v2/auth.verification-email.html",
      "utf8"
    );

    const rendered_html = ejs.render(html_template, {
      first_name: user.first_name,
      last_name: user.last_name,
    });

    const info = await transporter.sendMail({
      from: `${process.env.MAIL_FROM_NAME} <${process.env.MAIL_FROM}>`,
      to: `${user.email}`,
      subject: "Verification Email",
      html: rendered_html,
    });

    console.log(info);

    return info;
  } catch (err) {
    // console.log(err);
    next(err);
  }
};

/**
 * @Precondition
 * @Condition
 * @Postcondition
 */
export const initialize_session_cookie = async (req, res, session_token) => {
  try {
    res.cookie("nanta-session", session_token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "lax",
      maxAge: 60 * 60 * 1000,
    });
  } catch (err) {
    next(err);
  }
};
