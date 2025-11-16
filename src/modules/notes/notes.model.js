import mongoose from "mongoose";

const note_schema = new mongoose.Schema(
    {
        title: {type: String, required: true, trim: true, default: "Blank Note"},
        content: {type: String, required: true},
        user: {type: mongoose.Schema.Types.ObjectID, ref: "User", required: true}
    }
);

const Note = mongoose.model("Note", note_schema);

export default Note;