import express from "express";
import { rate_limit, validate_registration, validate_log_in, validate_verification_token, validate_token } from "./auth.middleware.js";
import { register_user, log_in_user, log_out_user, get_user, verify_email, send_verification_email } from "./auth.controller.js";

const router = express.Router();

router.post('/register', rate_limit, validate_registration, register_user);
router.post('/login', rate_limit, validate_log_in, log_in_user);
router.post('/logout', log_out_user);

router.get('/user', validate_token, get_user);

router.post('/verify-email/:verification_token', validate_verification_token, verify_email);

router.post('/resend-verification-email', validate_token, async (request, response) => {
    await send_verification_email(request, response);
    return response.success({}, "Verification email sent", 200);
});

export default router;