"""Build a small valid canon tree in a temp directory for broken-fixture tests."""
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

PLACE = """id: place.alpha
name: Alpha
type: place
kind: hold
summary: A hold.
facts:
  - It is small.
links:
  people: [person.bea]
sources: [world-bible.md#1]
"""
PERSON = """id: person.bea
name: Bea
type: person
kind: companion
region: place.alpha
summary: A person.
facts:
  - She is kind.
sources: [world-bible.md#1]
"""
CHAPTER = """chapter: 1
title: One
region: place.alpha
hero_name: Wrack
hero_knows_past: false
hero_abilities: []
alive: {person.bea: true}
corporations_fallen: []
dragon: running
known_to_mariners: []
known_to_agravars: []
companions_available: [person.bea]
sources: [campaign.md#1]
"""


class CanonCase(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.canon = Path(tmp.name)
        self.write("places/alpha.yaml", PLACE)
        self.write("people/bea.yaml", PERSON)
        self.write("chapters/ch01.yaml", CHAPTER)

    def write(self, rel, text):
        path = self.canon / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
