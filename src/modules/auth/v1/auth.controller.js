import { normalize_system_error_response } from "../../../custom.middleware.js";
import User from "./auth.model.js";
import jsonwebtoken from "jsonwebtoken";
import nodemailer from "nodemailer";
import Handlebars from "handlebars";
import fs from "fs";
import bcrypt from "bcryptjs";


export const register_user = async (request, response, next) => {
    try {
        const { first_name, last_name, email, password } = request.body;

        const hashed_password = await bcrypt.hash(password, 10);

        const user = new User({ first_name, last_name, email, password: hashed_password });
        await user.save();

        request.user = {email: user.email};

        await send_verification_email(request, response);

        return response.success({ user: { first_name, last_name, email } }, "User registered!", 201);
    }
    catch (error)
    {
        return normalize_system_error_response(error);
    }
}

export const log_in_user = async (request, response) => {
    try {
        const { email } = request.body;
        const user = await User.findOne({ email });
        const token = jsonwebtoken.sign({ user_id: user._id, email: user.email }, process.env.JWT_SECRET, {expiresIn: '1h'});
        
        response.cookie("nanta-jsonwebtoken", token, {
            httpOnly: true,
            secure: process.env.NODE_ENV === "production",
            sameSite: "lax",
            maxAge: 60 * 60 * 1000
        });

        return response.success({ user: { id: user._id, first_name: user.first_name, last_name: user.last_name, email: user.email } }, "User logged in!", 200);
    } catch (error) {
        return normalize_system_error_response(error, response);
    }
}

export const log_out_user = (request, response) => {
    response.cookie("nanta-jsonwebtoken", "", {
        httpOnly: true,
        secure: process.env.NODE_ENV === "production",
        sameSite: "lax",
        expires: new Date(0)
    });

    return response.success({}, "User logged out", 200);
}

export const get_user = async (request, response) => {
    const { email } = request.user;
    const user = await User.findOne({ email });

    return response.success({ user: { id: user._id, first_name: user.first_name, last_name: user.last_name, email: user.email, is_verified: user.is_verified } }, "User authenticated!", 200);
}

export const verify_email = async (request, response) => {
    request.user.is_verified = true;
    request.user.verification_token = null;
    await request.user.save();
    return response.success({}, "User email verified", 200);
}

export const send_verification_email = async (request, response) => {
    try {
        const { email } = request.user;
        const user = await User.findOne({ email });

        const { first_name, last_name } = user;

        const verification_token = jsonwebtoken.sign({ type: "email_verification", user_id: user._id, email: user.email }, process.env.JWT_SECRET, {expiresIn: '12h'});

        user.verification_token = verification_token;
        user.save();

        const verification_link = process.env.APP_DOMAIN + "/api/auth/verify-email/" + verification_token;

        const transporter = nodemailer.createTransport({
            host: process.env.MAIL_HOST,
            port: process.env.MAIL_PORT,
            secure: false,
            auth: {
                user: process.env.MAIL_USER,
                pass: process.env.MAIL_PASS,
            },
        });

        const email_source = fs.readFileSync("./src/modules/auth/emails/verification-email.html", "utf8");
        const email_template = Handlebars.compile(email_source);
        const html = email_template({ name: first_name, verification_link: verification_link });

        const info = await transporter.sendMail({
            from: `${process.env.MAIL_FROM_NAME} <${process.env.MAIL_FROM}>`,
            to: `${user.email}`,
            subject: "Nanta Verification Email",
            html: html,
        });
    } catch (error) {
        return normalize_system_error_response(error, response);
    }
}