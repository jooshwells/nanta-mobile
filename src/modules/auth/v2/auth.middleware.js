import { checkSchema, validationResult } from "express-validator";
import User from "./auth.model.js";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";

/**
 * @Precondition
 * The request body contains a JSON object with registration fields:
 * - first_name
 * - last_name
 * - email
 * - password
 * - confirm_password
 *
 * @Condition
 * Uses express-validator's checkSchema to:
 * - Ensure all fields are present.
 * - Ensure email is a valid email.
 * - Ensure email is not duplicated in database.
 * - Password is at least 8 characters.
 * - `confirm_password` matches `password`.
 *
 * @Postcondition
 * If validation passes, calls next() to continue the request.
 * If validation fails, responds with a status `400` and an `errors`
 * object in the response body.
 */
export const validate_registration_input = [
  checkSchema({
    first_name: {
      notEmpty: {
        errorMessage: "Please enter your first name",
      },
    },
    last_name: {
      notEmpty: {
        errorMessage: "Please enter your last name",
      },
    },
    email: {
      notEmpty: {
        errorMessage: "Please enter your email",
      },
      isEmail: {
        bail: true,
        errorMessage: "Please enter a valid email",
      },
      normalizeEmail: true,
      custom: {
        options: async (value) => {
          const user = await User.findOne({ email: value });
          // console.log(user);
          if (user) throw new Error("Email is already registered");

          return true;
        },
      },
    },
    password: {
      notEmpty: {
        errorMessage: "Please enter your password",
      },
      isLength: {
        options: { min: 8 },
        errorMessage: "Password must be at least 8 characters",
      },
    },
    confirm_password: {
      notEmpty: {
        errorMessage: "Please confirm your password",
      },
      custom: {
        options: (value, { req }) => {
          if (
            req.body.password &&
            req.body.password.length >= 8 &&
            value !== req.body.password
          )
            throw new Error("Passwords do not match");

          return true;
        },
      },
    },
  }),

  (req, res, next) => {
    const result = validationResult(req).mapped();
    // console.log(validationResult(req).mapped());
    if (Object.keys(result).length !== 0)
      return res.status(400).send({ errors: result });

    next();
  },
];

/**
 * @Precondition
 * The request body contains a JSON object with login fields:
 * email, password
 *
 * @Condition
 * Uses express-validator's checkSchema to:
 * - Ensure all fields are present.
 * - Password is at least 8 characters.
 * - `confirm_password` matches `password`.
 *
 * @Postcondition
 * If the JSON object is valid, pass the request onto the next
 * function with next(). Otherwise, if invalid, return a status of
 * 400 along with an errors object in the res.body.
 */
export const validate_login_input = [
  checkSchema({
    email: {
      notEmpty: {
        bail: true,
        errorMessage: "Please enter your email",
      },
      isEmail: {
        bail: true,
        errorMessage: "Please enter a valid email",
      },
      normalizeEmail: true,
      custom: {
        options: async (value, { req }) => {
          const user = await User.findOne({ email: value });
          if (!user) throw new Error("User not found");
          req.body.user = user;
          return true;
        },
      },
    },
    password: {
      custom: {
        options: async (value, { req }) => {
          if (!(await bcrypt.compare(value, req.body.user.password)))
            throw new Error("User not found");
          return true;
        },
      },
    },
  }),

  (req, res, next) => {
    const result = validationResult(req).mapped();
    // console.log(validationResult(req).mapped());
    if (Object.keys(result).length !== 0)
      return res
        .status(400)
        .send({ errors: { login: { msg: "Invalid email or password" } } });

    next();
  },
];

/**
 * @Precondition
 * @Condition
 * @Postcondition
 */
export const validate_session_token = async (req, res, next) => {
  try {
    //Check for token for mobile and if it exists remove the prefix
    let token = null;
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith("Bearer ")) {
      token = authHeader.substring(7);
    }

    if (!req.cookies["nanta-session"])
      return res.status(400).send({ authorization_status: "Unauthorized" });

    const session_token = jwt.verify(
      req.cookies["nanta-session"],
      process.env.JWT_SECRET
    );

    if (session_token.type !== "session-token")
      return res.status(400).send({ authorization_status: "Unauthorized" });

    const user = await User.findOne({ _id: session_token.user._id });

    if (!user)
      return res.status(400).send({ authorization_status: "Unauthorized" });

    req.user = user;

    next();
  } catch (err) {
    if (err.message === "jwt expired")
      return res.status(400).send({ authorization_status: "Unauthorized" });

    next(err);
  }
};

/**
 * @Precondition
 * @Condition
 * @Postcondition
 */
export const validate_verification_token = async (req, res, next) => {
  try {
    const verification_token = jwt.verify(
      req.params.token,
      process.env.JWT_SECRET
    );

    if (verification_token.type !== "email-verification-token")
      return res.status(400).send({ verification_status: "Invalid token" });

    const user = await User.findOne({ _id: verification_token.user._id });

    if (!user)
      return res.status(400).send({ verification_status: "Invalid token" });

    if (user.verification_token !== req.params.token)
      return res.status(400).send({ verification_status: "Invalid token" });

    req.body = { user: user };

    next();
  } catch (err) {
    return res.status(400).send({ verification_status: "Invalid token" });
  }
};
