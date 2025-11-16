import express from "express";
import { validate_session_token } from "../auth/v2/auth.middleware.js";
import {create_note, get_notes, update_note, delete_note} from "./notes.controller.js";

const router = express.Router();

// Create a new note
router.post("/create", validate_session_token, create_note);

// Get all notes for the user
router.get("/", validate_session_token, get_notes);

// Update an existing note by ID
router.put("/:id", validate_session_token, update_note);

// Delete a note by ID
router.delete("/:id", validate_session_token, delete_note);

export default router;
