import express from "express";

// Middleware import
import { validate_registration_input, validate_login_input, validate_session_token, validate_verification_token } from "./auth.middleware.js";

// Controller import
import { register_user, login_user, logout_user, authenticate_user, verify_user_email, send_verification_email, get_user_data } from "./auth.controller.js";

const router = express.Router();

// Authentication routes
router.post("/register", validate_registration_input, register_user);
router.post("/login", validate_login_input, login_user);
router.post("/logout", logout_user);

// User and email verification routes
router.get("/user", validate_session_token, get_user_data);
router.get("/user/authenticate", validate_session_token, authenticate_user);
router.post("/user/verify-email/resend", validate_session_token, send_verification_email);
router.post("/user/verify-email/:token", validate_verification_token, verify_user_email);

export default router;