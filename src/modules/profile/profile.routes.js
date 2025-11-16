import express from "express";

import { update_profile } from "./profile.controller.js";
import { validate_session_token } from "../auth/v2/auth.middleware.js";

const router = express.Router();

// Profile routes
router.put("/update-info", validate_session_token, update_profile);

export default router;