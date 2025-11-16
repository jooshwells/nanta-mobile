import rateLimit from "express-rate-limit";
import { body, checkSchema, validationResult } from "express-validator";
import User from "./auth.model.js";
import { response } from "express";
import bcrypt from "bcryptjs";
import jsonwebtoken from "jsonwebtoken";

export const rate_limit = rateLimit({
    windowMs: 60 * 1000,
    max: 20,
    standardHeaders: true,
    legacyHeaders: false,
    message: {
        error: "Too many requests, please try again later."
    }
});

export const validate_registration = [
    checkSchema({
        email: {
            escape: true,
            notEmpty: {
                errorMessage: "Please enter your email"
            },
            isEmail: { 
                bail: true,
                errorMessage: "Please enter a valid email"
            },
            normalizeEmail: true,
            custom: { 
                options: async (value) => {
                    const user = await User.findOne({ email: value });
                    if (user)
                        throw new Error("Email is already registered");

                    return true;
                },
            }
        },
        first_name: {
            notEmpty: {
                errorMessage: "Please enter your first name"
            },
            trim: true,
            escape: true
        },
        last_name: {
            notEmpty: {
                errorMessage: "Please enter your last name"
            },
            trim: true,
            escape: true
        },
        password: {
            notEmpty: {
                errorMessage: "Please enter your password"
            },
            isLength: {
                options: { min: 8 },
                errorMessage: 'Password must be at least 8 characters'
              }
        },
        confirm_password: {
            custom: { 
                options: (value, {req}) => {
                    if (value !== req.body.password)
                        throw new Error("Passwords do not match");

                    return true;
                },
            }
        }
    }),

    (request, response, next) => {
        const errors_array = validationResult(request).array();

        if (errors_array.length) {
            const errors_object = errors_array.reduce((object, error) => {
                object[error.path] = error.msg;
                return object;
            }, {});
            return response.error(errors_object, "Validation Error", 400);
        };

        next();
    }
];

export const validate_log_in = [
    checkSchema({
        email: {
            escape: true,
            notEmpty: {
                errorMessage: "Please enter your email"
            },
            isEmail: {
                bail: true,
                errorMessage: "Please enter your email"
            },
            normalizeEmail: true,
            custom: {
                options: async (value) => {
                    const user = await User.findOne({ email: value });
                    if (!user)
                        throw new Error("Invalid credentials");

                    return true;
                }
            }
        },
        password: {
            notEmpty: {
                errorMessage: "Invalid credentials"
            },
            custom: {
                options: async (value, {req}) => {
                    const user = await User.findOne({ email: req.body.email });
                    
                    if (!(await bcrypt.compare(value, user.password)))
                        throw new Error("Invalid credentials");

                    return true;
                }
            }
        },
    }),

    (request, response, next) => {
        const errors_array = validationResult(request).array();

        if (errors_array.length) {
            const errors_object = errors_array.reduce((object, error) => {
                object[error.path] = error.msg;
                return object;
            }, {});
            // return response.error(errors_object, "Validation Error", 400);
            return response.error({}, "Validation Error", 400);
        };

        next();
    }
]

export const validate_token = (request, response, next) => {
    const token = request.cookies["nanta-jsonwebtoken"];

    if (!token)
        return response.error({}, "Unauthorized", 401);

    try {
        const decoded_token = jsonwebtoken.verify(token, process.env.JWT_SECRET);
        request.user = decoded_token;
        next();
    } catch (error) {
        return response.error({}, "Invalid or expired token", 401); 
    }
}

export const validate_verification_token = async (request, response, next) => {
    try {
        const verification_token = request.params.verification_token;

        if(!verification_token)
            throw new Error("Missing token");

        const decoded_verification_token = jsonwebtoken.verify(verification_token, process.env.JWT_SECRET);

        if (decoded_verification_token.type !== "email_verification")
            throw new Error("Invalid token type");

        const user = await User.findOne({ email: decoded_verification_token.email });

        if (!user)
            throw new Error("User not found");

        if (user.is_verified) 
            throw new Error("User already verified");

        if (user.verification_token !== verification_token)
            throw new Error("Invalid token");

        request.user = user;
        next();
        
    } catch (error) {
        return response.error({}, error.message, 401); 
    }
}