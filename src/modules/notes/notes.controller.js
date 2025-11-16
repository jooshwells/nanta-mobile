import { normalize_system_error_response } from "../../custom.middleware.js";
import Note from "./notes.model.js";

// Create and save a new note
export const create_note = async (request, response) => {
    try {
        const { title, content } = request.body;
        const user_id = request.user && (request.user.id || request.user._id);
        if (!user_id) {
            return response.status(401).json({ message: "User not authenticated" });
        }

        // Uses default "Blank Note" if undefined
        const note = new Note({title: title || undefined, content, user: user_id});

        await note.save();

        return response.status(200).send("Note created successfully!");
    } catch (error) {
       return normalize_system_error_response(error, response);
    }
};

// Get all notes for the logged-in user
export const get_notes = async (request, response) => {
    try {
        const user_id = request.user && (request.user.id || request.user._id);

        if (!user_id) {
            return response.status(401).json({ message: "User not authenticated" });
        }

        const notes = await Note.find({ user: user_id }).sort({ updated_at: -1 });

        return response.status(200).json({ notes, message: "Notes retrieved successfully!" });
    } catch (error) {
        return normalize_system_error_response(error, response);
    }
};

// Update an existing note
export const update_note = async (request, response) => {
    try {
        const { id } = request.params;
        const { title, content } = request.body;
        const user_id = request.user && (request.user.id || request.user._id);

        const note = await Note.findOneAndUpdate(
            { _id: id, user: user_id },
            { title, content },
            { new: true }
        );

        if (!note) {
            return response.status(404).json({ message: "Note not found or unauthorized!" });
        }

        return response.status(200).json({ message: "Note updated successfully!" });
    } catch (error) {
        return normalize_system_error_response(error, response);
    }
};

// Delete a note
export const delete_note = async (request, response) => {
    try {
        const { id } = request.params;
        const user_id = request.user && (request.user.id || request.user._id);

        const note = await Note.findOneAndDelete({ _id: id, user: user_id });

        if (!note) {
            return response.status(404).json({ message: "Note not found or unauthorized!" });
        }

        return response.status(200).json({ message: "Note deleted successfully!" });
    } catch (error) {
        return normalize_system_error_response(error, response);
    }
};
